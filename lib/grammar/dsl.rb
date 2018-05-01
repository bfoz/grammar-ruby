module Grammar
    module DSL
	def self.build(klass, *elements, &block)
	    if block_given?
		grammar_name = elements.shift if elements.first&.is_a?(Symbol)
		raise ArgumentError("Block or elements, but not both") unless elements.empty?

		subklass = Grammar::Builder.new(klass).evaluate(&block)
		if grammar_name
		    const_set(grammar_name, subklass)
		else
		    subklass
		end
	    else
		raise ArgumentError("Block or elements, but not both") if elements.empty?
		klass.with(*elements)
	    end
	end

	def alternation(*elements, &block)
	    Grammar::DSL.build(Grammar::Alternation, *elements, &block)
	end

	def concatenation(*elements, &block)
	    Grammar::DSL.build(Grammar::Concatenation, *elements, &block)
	end
    end
end
