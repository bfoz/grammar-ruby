class Grammar::Recursion
    attr_accessor :grammar

    def initialize(grammar=nil)
	@grammar = grammar
    end

    def ==(other)
	self.grammar == other.grammar
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
