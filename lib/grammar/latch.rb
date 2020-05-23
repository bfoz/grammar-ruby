require_relative 'base'
require_relative 'repeatable'

module Grammar
    class Latch < Base
	class << self
	    include Repeatable

	    # @return [Alternation, Concatenation, Repetition]	The referenced grammar element
	    attr_reader :grammar

	    def with(grammar)
		raise ArgumentError.new('grammar must not be nil') if grammar.nil?

		Class.new(self) do
		    @grammar = grammar

		    class << self
			# Generic equality
			def ==(other)
			    other.is_a?(Class) and (other <= self.superclass) and (self.grammar === other.grammar)
			end

			# Case equality
			def ===(other)
			    if other.is_a?(Class)
				other.equal?(self.superclass) or ((other < self.superclass) and (self.grammar === other.grammar))
			    else
				other.is_a?(self)		# Classes are always triple-equal to their instances
			    end
			end

			# Hash equality
			alias eql? ==
		    end
		end
	    end

	    def label
		(respond_to?(:name) && name) || "Latch<#{self.object_id}>"
	    end

	    # @return [Bool]    True if the {latch} pattern is optional
	    def optional?
		self.grammar&.respond_to?(:optional?) and self.grammar&.optional?
	    end
	end
    end
end
