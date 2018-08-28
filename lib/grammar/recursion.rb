class Grammar::Recursion < SimpleDelegator
    attr_accessor :grammar

    def initialize(grammar=nil)
	super
	@grammar = grammar
    end

    def ==(other)
	# The superclass method checks for object_id equality, which allows for short-circuit logic when +other+ is the same object as +self+
	super or (self.grammar == other.grammar)
    rescue NoMethodError
    	nil
    end

    # @group Predicates

    # @return [Bool]	Returns true if the first element is left recursive
    def left_recursive?
	self.grammar&.respond_to?(:left_recursive?) and self.grammar&.left_recursive?
    end

    # All {Recursions} are assumed to be optional unless otherwise noted. This helps avoid infinite recursions.
    # @return [True]
    def optional?
	true
    end

    # @return [Bool]	Returns true if grammar is recursive
    def recursive?
    	self.grammar&.respond_to?(:recursive?) and self.grammar&.recursive?
    end

    # @endgroup

    def inspect
	"<Recursion:" + self.grammar.inspect + ">"
    end

    class << self
	def with(grammar)
	    self.new(grammar)
	end
    end
end
