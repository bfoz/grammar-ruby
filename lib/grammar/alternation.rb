require 'forwardable'

require_relative 'repeatable'

module Grammar
    class Alternation
	extend Forwardable

	attr_reader :location
	attr_reader :match

	def_delegators :@match, :length, :to_s

	# Create a new {Alternation} from the given {Pattern}s
	def initialize(match, location:nil)
	    @location = location
	    @match = match
	end

	# Generic equality
	def ==(other)
	    ((other.is_a?(self.class) and (@match == other.match)) or (@match == other))
	end

	# Case equality
	def ===(other)
	    other.is_a?(self.class) and (@match == other.match)
	end

	# Hash equality
	def eql?(other)
	    (other.is_a?(self.class) and (self.location == other.location) and (@match == other.match)) or @match.eql?(other)
	end

	def inspect(indent=0)
	    ("\t"*indent) + "#<#{self.class.name}@#{self.location}:'#{self.match.inspect}'>"
	end

	class << self
	    include Enumerable
	    extend Forwardable
	    include Repeatable

	    attr_reader :elements

	    def_delegators :@elements, :[], :each, :first, :last, :length

	    def with(*args)
		Class.new(self) do
		    @elements = args.clone

		    class << self
			# Generic equality
			def ==(other)
			    other.is_a?(Class) and (other <= Alternation) and (self.elements === other.elements)
			end

			# Case equality
			def ===(other)
			    other.is_a?(Class) and (other.equal?(Alternation) or ((other < Alternation) and (self.elements === other.elements)))
			end

			# Hash equality
			alias eql? ==
		    end
		end
	    end

	    def name
		super or "Alternation<#{self.object_id}>"
	    end

	    # Case equality
	    def ===(other)
		other.is_a?(Class) and (other <= self)
	    end

	    def hash
		@elements.map(&:hash).reduce(&:+)
	    end

	    def |(other)
		self.with(*elements, other)
	    end

	    def +(other)
		Concatenation.new(self, other)
	    end

	    def label
		(respond_to?(:name) && name) || object_id
	    end

	    # @return [Bool]	Returns true if any element is recursive
	    def left_recursive?
		elements.any? do |element|
		    element.is_a?(Grammar::Recursion) or (element.respond_to?(:left_recursive) and element.left_recursive?)
		end
	    end

	    def to_re
		elements_to_re = self.elements.map {|e| e.to_re rescue e.to_s}.join('|')
		if self.elements.length > 1
		    '('+elements_to_re+')'
		else
		    elements_to_re
		end
	    end

	    def to_regexp
		Regexp.new(self.to_re)
	    end

	    def inspect
		[self.name, self.to_re].compact.join(':')
	    end

	    def to_s
		self.elements ? self.to_re : super
	    end
	end
    end
end
