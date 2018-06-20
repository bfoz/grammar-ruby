class Grammar::Recursion
    attr_accessor :grammar

    def initialize(grammar=nil)
	@grammar = grammar
    end

    def ==(other)
	self.grammar == other.grammar
    rescue NoMethodError
    	nil
    end

    # @return [Bool]	Returns true if the first element is left recursive
    def left_recursive?
	self.grammar&.respond_to?(:left_recursive?) and self.grammar&.left_recursive?
    end

    # @return [Bool]	Returns true if grammar is recursive
    def recursive?
    	self.grammar&.respond_to?(:recursive?) and self.grammar&.recursive?
    end

    class << self
	def with(grammar)
	    self.new(grammar)
	end

	def inspect
	    "<Recursion:" + self.grammar.inspect + ">"
	end
    end
end
