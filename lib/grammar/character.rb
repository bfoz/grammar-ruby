require 'forwardable'

# require_relative 'repeatable'

module Grammar
    # A {Pattern} that represents a character class
    class Character
	extend Forwardable

	attr_reader :location
	attr_reader :match

	def_delegators :@match, :length, :to_s

	# Create a new {Character} from the given {String}
	def initialize(match, location:nil)
	    @location = location
	    @match = match
	end

	def initialize_copy(original)
	    super
	    @match = @match.dup
	end

	def ==(other)
	    (other.is_a?(self.class) and (self.match == other.match)) or (self.match == other)
	end

	def eql?(other)
	    (other.is_a?(self.class) and (self.location == other.location) and (self.match == other.match)) or self.match.eql?(other)
	end

	def inspect(indent=0)
	    ("\t"*indent) + "#{self.class.name || self.class.inspect}:'#{self.match.inspect[1..-2]}'@#{self.location}"
	end

	def repeated?
	    self.class.repeated?
	end

	class << self
	    # include Repeatable

	    attr_reader :elements

	    def with(*args)
		Class.new(self) do
		    @elements = args.clone
		end
	    end

	    def first;  elements.first; end
	    def last;   elements.last; end

	    def name
		super or "Character<#{self.object_id}>"
	    end

	    # Generic equality
	    def ==(other)
		return false unless other.is_a?(Class)
		(other.equal?(Character) || (other < Character)) && (elements == other.elements) && (self.maximum == other.maximum) && (self.minimum == other.minimum)
	    end

	    # Hash equality
	    def eql?(other)
		other.respond_to?(:name) and (self.name == other.name) and (self == other)
	    end

	    def hash
		@elements.map(&:hash).reduce(&:+)
	    end

	    # Case equality
	    def ===(other)
		if other.is_a?(Class) and (other.equal?(Character) || (other.respond_to?(:<) and (other < Character)))
		    true
		else
		    super
		end
	    end

	    def |(other)
		if other.is_a?(String)
		    self.with(*elements, other)
		else
		    self.with(*elements, *other.elements)
		end
	    end

	    # Specialize this class to create a new Character that doesn't match the given characters
	    # @return [Character]
	    def except(*characters)
		_elements = characters.reduce(self.elements) do |elements, character|
		elements.flat_map do |element|
			if element.is_a?(Range)
			    if character.is_a?(Range)
				if element.include?(character.first)
				    if element.include?(character.last)
					if element.first == character.first
					    if element.last == character.last
						nil
					    else
						Range.new(character.last.ord.next.chr, element.last)
					    end
					elsif element.last == character.last
					    Range.new(element.first, (character.first.ord-1).chr)
					else
					    # Split the Range
					    left = Range.new(element.first, (character.first.ord-1).chr)
					    right = Range.new(character.last.ord.next.chr, element.last)
					    [left, right]
					end
				    else
					Range.new(element.first, (character.first.ord-1).chr)
				    end
				elsif element.include?(character.last)
				    Range.new(character.last.ord.next.chr, element.last)
				else
				    element
				end
			    elsif character.is_a?(String)
				if element.include?(character)
				    # Break the element at the character
				    [Range.new(element.first, (character.ord-1).chr), Range.new(character.ord.next.chr, element.last)]
				else
				    element 	# Do nothing
				end
			    else
				raise ArgumentError.new("Invalid character type: #{character}")
			    end
			elsif element.is_a?(String)
			    if character.is_a?(Range)
				element unless character.include?(element)
			    elsif character.is_a?(String)
				element unless element == character
			    else
				raise ArgumentError.new("Invalid character type: #{character}")
			    end
			else
			    raise RuntimeError.new("Invalid Character element: #{element}")
			end
		    end.compact
		end

		self.with(*_elements)
	    end

	    # @param c [String]	the character to check
	    # @return [Bool]	true if the given character is a member of the [Character] class
	    def include?(c)
		self.elements.find do |element|
		    case element
			when Range then element.include?(c)
			else element == c
		    end
		end
	    end

	    def label
		(respond_to?(:name) && name) || object_id
	    end

	    def to_re
		suffix = regex_repetition_suffix() || ''
		escaped = self.elements.map do |e|
		    case e
			when Range then e.begin.inspect[1..-2] + '-' + e.end.inspect[1..-2]
			else
			    if ['-', '*', '+', '(', ')', '[', ']', '{', '}', '.', '?'].include?(e)
				'\\' + e
			    else
				e.inspect[1..-2]
			    end
		    end
		end
		'['+escaped.join+']' + suffix
	    end

	    def to_regexp
		Regexp.new(self.to_re)
	    end

	    def inspect
		self.name + ':' + (self.elements ? self.to_re : '')
	    end

	    def to_s
		self.elements ? self.to_re : ''
	    end
	end
    end

    # A convenience wrapper for encapsulating the creation of {Character} classes
    def self.Character(*args)
	Character.with(*args)
    end
end
