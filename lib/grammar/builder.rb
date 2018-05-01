require 'grammar'

require_relative 'dsl'

module Grammar
    class Builder
	include Grammar::DSL

	def initialize(klass)
	    @elements = []
	    @klass = klass
	end

	# Evaluate a block in the contect of @klass and return a new instance of @klass
	#  Use the trick found here http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	#  to allow the DSL block to call methods in the enclosing *lexical* scope
	# @return [Alternation,Concatenation]	A new subclass initialized with the given block
	def evaluate(&block)
	    @self_before_instance_eval = eval "self", block.binding
	    self.instance_eval(&block)
	    @klass.with(*@elements)
	end

	# The second half of the instance_eval delegation trick mentioned at
	#   http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	def method_missing(method, *args, &block)
	    if @self_before_instance_eval.respond_to? method
		@self_before_instance_eval.send method, *args, &block
	    else
		super if defined?(super)
	    end
	end

	def element(arg)
	    @elements.push arg
	end

	def elements(*args)
	    args.each {|arg| self.element(arg) }
	end
    end
end