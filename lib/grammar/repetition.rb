require_relative 'base'

class Grammar::Repetition < Grammar::Base
    include Enumerable
    extend Forwardable

    attr_reader :elements
    attr_reader :location

    def_delegators :@elements, :[], :each, :first, :last

    def initialize(*args, location:nil)
	@elements = args
	@location = location
    end

    # Generic equality
    def ==(other)
	if other.is_a?(self.class)
	    @elements == other.elements
	elsif other.is_a?(String)
	    @elements.join == other
	end
    end

    # Case equality
    def ===(other)
	other.is_a?(self.class) and (@elements == other.elements)
    end

    # Hash equality
    def eql?(other)
	(other.is_a?(self.class) and (self.location == other.location) and (@grammar == other.grammar)) or @grammar.eql?(other)
    end


    class << self
	# @return [Alternation, Concatenation] The repeated grammar element
	attr_reader :grammar

	# @return [Integer] The maximum allowed number of repetitions (inclusive)
	attr_reader :maximum

	# @return [Integer] The minimum required number of repetitions
	attr_reader :minimum

	# Match between minimum and maximum times (inclusive), or match exactly minimum times if maximum is nil
	# @param [Grammar] The {Grammar} to be repeated
	# @option [Integer] minimum The minimum number of repetitions to accept
	# @option [Integer] maximum The maximum number of repetitions to allow (inclusive)
	# @return [Repetition] A new {Repetition}
	def with(grammar, maximum:, minimum:)
	    raise ArgumentError.new('grammar must not be nil') if grammar.nil?

	    require_relative 'repeatable'

	    Class.new(self) do

		# Override the normal repetition factory methods with methods that are more appropriate for the subclass
		extend Grammar::Repeatable

		@grammar = grammar
		@maximum = maximum
		@minimum = minimum

		class << self
		    # Generic equality
		    def ==(other)
			other.is_a?(Class) and (other <= Grammar::Repetition) and (self.grammar === other.grammar) and (self.maximum == other.maximum) and (self.minimum == other.minimum)
		    end

		    # Case equality
		    def ===(other)
			if other.is_a?(Class)
			    other.equal?(Grammar::Repetition) or ((other < Grammar::Repetition) and (self.grammar === other.grammar) and (self.maximum == other.maximum) and (self.minimum == other.minimum))
			else
			    other.is_a?(self)							# Classes are always triple-equal to their instances
			end
		    end

		    # Hash equality
		    alias eql? ==
		end
	    end
	end

	# @return [Array] A single-item Array containing `#grammar`. For compatability with {Alternation} and {Concatenation}.
	def elements
	    [self.grammar]
	end

	def hash
	    self.elements.map(&:hash).reduce(&:+)
	end

	# Zero or more repetitions
	# @param [Grammar] The {Grammar} to be repeated
	def any(grammar)
	    self.with(grammar, maximum:nil, minimum:0)
	end

	# @param [Integer] The minimum required repetitions
	# @param [Grammar] The {Grammar} to be repeated
	def at_least(minimum, grammar)
	    self.with(grammar, maximum:nil, minimum:minimum)
	end

	# @param [Integer] The maximum allowed repetitions (inclusive)
	# @param [Grammar] The {Grammar} to be repeated
	def at_most(maximum, grammar)
	    self.with(grammar, maximum:maximum, minimum:nil)
	end

	# @param [Integer]  Accept up to, but not including, maximum repetitions
	# @return [Repetition]
	def less_than(maximum, grammar)
	    raise ArgumentError('Cannot have fewer than 0 repetitions') if maximum < 1
	    self.at_most(maximum-1, grammar)
	end

	# @param [Integer]  Accept more than minimum repetitions
	# @return [Repetition]
	def more_than(minimum, grammar)
	    self.at_least(minimum+1, grammar)
	end

	# Require at least one repetition
	# @param [Grammar] The {Grammar} to be repeated
	# @return [Repetition]
	def one_or_more(grammar)
	    self.at_least(1, grammar)
	end

	# Require exactly 0 or 1 instance
	# @param [Grammar] The {Grammar} to be repeated
	# @return [Repetition]
	def optional(grammar)
	    self.with(grammar, maximum:1, minimum:0)
	end
	alias maybe optional

	# Match between minimum and maximum times (inclusive), or match exactly minimum times if maximum is nil
	# @param [Grammar] The {Grammar} to be repeated
	# @return [Repetition]
	def repeat(grammar, minimum, maximum=nil)
	    self.with(grammar, maximum:(maximum or minimum), minimum:minimum)
	end

	# Require zero or more repetitions
	# @param [Grammar] The {Grammar} to be repeated
	def zero_or_more(grammar)
	    self.any(grammar)
	end

	# @group Predicates

	# @attr_reader [Bool] true for zero-or-more repetitions
	def any?
	    self.maximum.nil? and self.minimum.zero?
	end

	def at_least?(minimum)
	    self.maximum.nil? and (self.minimum <= minimum)
	end

	# @attr_reader [Bool]	true if [minimum, maximum] == [1, nil]
	def one_or_more?
	    self.maximum.nil? and (1 == self.minimum)
	end

	# @attr_reader [Bool]	true if [minimum, maximum] == [0, 1]
	def optional?
	    (1 == self.maximum) and self.minimum.zero?
	end
	alias maybe? optional?

	# @attr_reader [Bool]	true if (minimum or maximum)
	def repeated?
	    self.minimum or self.maximum
	end

	# @endgroup

	# @return [String]	Returns a repetition suffix, or nil if no suffix is required
	private def regex_repetition_suffix
	    if self.maximum and self.minimum
		if self.maximum == self.minimum
		    if self.maximum != 1
			"{#{self.minimum}}"
		    end
		elsif self.minimum.zero? and (1 == self.maximum)
		    '?'
		else
		    "{#{self.minimum},#{self.maximum}}"
		end
	    elsif self.maximum or self.minimum
		if 1 == self.maximum
		    '?'
		elsif 0 == self.minimum
		    '*'
		elsif 1 == self.minimum
		    '+'
		else
		    "{#{self.minimum},#{self.maximum}}"
		end
	    end
	end

	def to_regexp
	    _suffix = regex_repetition_suffix()
	    if _suffix
		_re = self.grammar.to_re
		if _re.start_with?('(') and _re.end_with?(')')
		    Regexp.new(_re + _suffix)
		else
		    Regexp.new('(' + _re + ')' + _suffix)
		end
	    else
		Regexp.new(self.grammar.to_re)
	    end
	end

	def inspect
	    "<Repetition:" + self.grammar.inspect + (regex_repetition_suffix() or '') + ">"
	end
    end
end
