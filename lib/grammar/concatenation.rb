require_relative 'base'
require_relative 'repeatable'

module Grammar
    class Concatenation < Base
	include Enumerable
	extend Forwardable

	attr_reader :elements
	attr_reader :location

	def_delegators :@elements, :[], :each, :first, :last

	def initialize(*args, location:nil)
	    raise ArgumentError.new("Need #{self.class.elements.length} arguments, got #{args.length}") unless args.length == self.class.elements.length

	    @elements = args || []
	    @location = location
	end

	# Generic equality
	def ==(other)
	    (other.is_a?(self.class) and other.respond_to?(:elements) and (self.elements == other.elements)) or (self.elements.join == other)
	end

	# Case equality
	alias === ==

	# Hash equality
	def eql?(other)
	    if other.is_a?(String)
		self.elements.join == other
	    elsif other.is_a?(self.class)
		(self.location == other.location) and (self.elements == other.elements)
	    end
	end

	def length
	    self.elements.map(&:length).reduce(:+)
	end

	def inspect(indent=0)
	    prefix = "#<#{self.class.label}@#{self.location}"
	    parts = self.elements.flat_map do |e|
		e.inspect(indent+1) rescue ("\t"*(indent+1)) + e.inspect
	    end
	    if parts.empty?
		("\t"*indent) + "#{prefix}>"
	    else
		("\t"*indent) + "#{prefix}\n" + parts.join("\n") + "\n" + ("\t"*indent) + ">"
	    end
	end

	def to_s
	    self.elements.map(&:to_s).join
	end

	class << self
	    include Enumerable
	    extend Forwardable
	    include Repeatable

	    attr_reader :elements

	    def_delegators :@elements, :[], :each, :first, :last

	    def with(*args)
		Class.new(self) do
		    @elements = args.clone

		    class << self
			# Generic equality
			def ==(other)
			    other.is_a?(Class) and (other <= Concatenation) and (self.elements === other.elements)
			end

			# Case equality
			def ===(other)
			    (other.is_a?(Class) and (other.equal?(Concatenation) or ((other < Concatenation) and (self.elements === other.elements)))) or
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

	    # Create a new {Concatenation} using the given grammar element
	    # @note The receiver will be splatted into the new {Alternation} if it hasn't been named
	    # @return [Concatenation]
	    def +(other)
		_elements = self.name ? [self] : elements
		self.with(*_elements, other)
	    end

	    def drop(n=1)
		self.with(*self.elements.drop(n))
	    end

	    def label
		(respond_to?(:name) && name) || "Concatenation<#{self.object_id}>"
	    end

	    # @return [Bool]	Returns true if the first element is recursive
	    def left_recursive?
		elements.first.is_a?(Grammar::Recursion) or (elements.first.respond_to?(:left_recursive?) and elements.first.left_recursive?)
	    end

	    # @return [Bool]	Returns true if the first element is recursive
	    def recursive?
		elements.any? {|element| element.is_a?(Grammar::Recursion) or (element.respond_to?(:recursive?) and element.recursive?) }
	    end

	    # Allow explicit conversion to {Array}
	    # @return [Array]
	    def to_a
		self.elements ? self.elements : nil
	    end

	    def to_re
		elements_to_re = self.elements.compact.map {|e| e.to_re rescue e.to_s}.map {|a| a=="\n" ? "\\n" : a}
		elements_to_re.join
	    end

	    def inspect
		[self.label, self.to_re].compact.join(':')
	    end

	    def to_s
		self.elements ? self.to_re : super
	    end
	end
    end
end
