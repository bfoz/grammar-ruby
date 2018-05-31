require_relative 'recursion'

module Grammar
    module DSL
	def alternation(*elements, &block)
	    Grammar::Builder.build(Grammar::Alternation, *elements, &block)
	end

	def concatenation(*elements, &block)
	    Grammar::Builder.build(Grammar::Concatenation, *elements, &block)
	end

	refine Module do
	    include Grammar::DSL
	end

	refine String do
	    include Grammar::Repeatable

	    def |(other)
		Grammar::Alternation.with(self, other)
	    end

	    # Overload addition to perform concatenation unless the argument is a String
	    def +(other)
		case other
		    when Alternation, Recursion, Repetition	then Grammar::Concatenation.with(self, other)
		    when Concatenation				then Grammar::Concatenation.with(self, *other.elements)
		    else
			super
		end
	    end
	end
    end
end

# This is below Grammar::DSL because of circular reference issues
require_relative 'builder'
