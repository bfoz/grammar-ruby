require 'forwardable'

require_relative 'base'
require_relative 'repeatable'

module Grammar
    class Alternation < Base
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
	    ("\t"*indent) + "#<#{self.class.label}@#{self.location}:'#{self.match.inspect}'>"
	end

	# Allow explicit conversion to {Array}
	# @return [Array]
	def to_a
	    [self.match]
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
			    (other.is_a?(Class) and (other.equal?(Alternation) or ((other < Alternation) and (self.elements === other.elements)))) or
				other.is_a?(self)							# Classes are always triple-equal to their instances
			end

			# Hash equality
			alias eql? ==
		    end
		end
	    end

	    def hash
		@elements.map(&:hash).reduce(&:+)
	    end

	    # Create a new {Alternation} using the given grammar element
	    # @note The receiver will be splatted into the new {Alternation} if it hasn't been named
	    # @return [Alternation]
	    def |(other)
		_elements = self.name ? [self] : elements
		self.with(*_elements, other)
	    end

	    def label
		(respond_to?(:name) && name) || "Alternation<#{self.object_id}>"
	    end

	    # @note An {Alternation} is left-recursive when ever any of its elements are in any way recursive
	    # @note An {Alternation} is left-recursive whenever any of its elements are in any way recursive
	    # @param [Grammar]	The potential recursion root to check for. Defaults to self.
	    # @return [Bool]	Returns true if any element is recursive
	    def recursive?(root = nil, *path)
		if root.nil?
		    root = self
		else
		    return true if self.equal?(root)

		    # If self is in path, then we've found a recursion, but not the recursion we're looking for
		    # Consequently, we have to return here to avoid getting stuck in an infinite loop
		    return false if path.include?(self)

		    # If we're still looking, and root isn't self, then add self to the path and carry on
		    path.push self
		end

		elements.any? do |element|
		    (element.respond_to?(:recursive?) and element.recursive?(root, *path)) or (element.respond_to?(:left_recursive) and element.left_recursive?(root, *path))
		end
	    end
	    alias left_recursive? recursive?

	    # Allow explicit conversion to {Array}
	    # @return [Array]
	    def to_a
		self.elements ? self.elements : nil
	    end

	    def to_re
		elements_to_re = self.elements.map {|e| e.to_re rescue e.to_s}.join('|')
		if self.elements.length > 1
		    '('+elements_to_re+')'
		else
		    elements_to_re
		end
	    end

	    def inspect
		[self.label, self.to_re].compact.join(':')
	    end

	    def to_s
		self.label or super
	    end
	end
    end
end
