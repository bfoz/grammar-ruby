require_relative 'repeatable'

module Grammar
    class Concatenation
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

	def ==(other)
	    other.respond_to?(:elements) ? (self.elements == other.elements) : (self.elements.join == other)
	end

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
	    prefix = "#<#{self.class.name}@#{self.location}"
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

	    def_delegators :@elements, :each, :first, :last

	    def with(*args)
		Class.new(self) do
		    @elements = args.clone
		end
	    end

	    def name
		super or "Concatenation<#{self.object_id}>"
	    end

	    # Generic equality
	    def ==(other)
		return false unless other.is_a?(Class)
		(other.equal?(Concatenation) || (other < Concatenation)) && (elements == other.elements)
	    end

	    # Hash equality
	    alias eql? ==

	    def hash
		@elements.map(&:hash).reduce(&:+)
	    end

	    # Case equality
	    def ===(other)
		if other.is_a?(Class) and (other.equal?(Concatenation) || (other.respond_to?(:<) and (other < Concatenation)))
		    true
		else
		    super
		end
	    end

	    def |(other)
		Alternation.with(self, other)
	    end

	    def +(other)
		self.with(*elements, other)
	    end

	    def drop(n=1)
		self.with(*self.elements.drop(n))
	    end

	    def label
		(respond_to?(:name) && name) || object_id
	    end

	    # @return [Bool]	Returns true if the first element is recursive
	    def left_recursive?
		elements.first.is_a?(Grammar::Recursion) or (elements.first.respond_to?(:left_recursive?) and elements.first.left_recursive?)
	    end

	    # @return [Bool]	Returns true if the first element is recursive
	    def recursive?
		elements.any? {|element| element.is_a?(Grammar::Recursion) or (element.respond_to?(:recursive?) and element.recursive?) }
	    end

	    def to_re
		elements_to_re = self.elements.compact.map {|e| e.to_re rescue e.to_s}.map {|a| a=="\n" ? "\\n" : a}
		elements_to_re.join
	    end

	    def to_regexp
		Regexp.new(self.to_re)
	    end

	    def inspect
		[self.name, self.to_re].compact.join(':')
	    end

	    def to_s
		self.elements ? self.to_re : ''
	    end
	end
    end
end
