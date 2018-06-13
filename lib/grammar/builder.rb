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
	# @param [Recursion] The recursion proxy object to be passed to blocks that have non-zero arity
	# @return [Alternation,Concatenation]	A new subclass initialized with the given block
	def evaluate(recursion_proxy=nil, &block)
	    @self_before_instance_eval = eval "self", block.binding
	    if block.arity.zero?
		self.instance_eval(&block)
	    else
		raise ArgumentError.new("A recursion proxy object is required") unless recursion_proxy
		self.instance_exec(recursion_proxy, &block)
	    end
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

	def self.build(klass, *elements, &block)
	    if block_given?
		grammar_name = elements.shift if elements.first&.is_a?(Symbol)
		raise ArgumentError.new("Block or elements, but not both") unless elements.empty?

		if grammar_name and block.arity.nonzero?
		    raise ArgumentError.new('Name or anonymous, but not both')
		end

		if grammar_name or block.arity.nonzero?
		    recursion_wrapper = nil
		    _recursion_wrapper = Grammar::Recursion.new
		end

		if grammar_name
		    # If it's stupid and it works, it's not stupid
		    # This injects a const_missing handler into block's lexically enclosing Module for
		    #  the purpose of catching any uses of the not-yet-defined recursive grammar-in-progress.
		    # The const_missing handler creates and returns a proxy object for the missing constant, or
		    #  passes the call to the original handler, if any.
		    # NOTE that this is the *lexically* enclosing Module, which may in fact be Object.ancestors.first if
		    #  the enclosing module was created with Module.new (because that doesn't create a new lexical scope)
		    lexical_self = eval("Module.nesting.first or Object.ancestors.first", block.binding)

		    # But first, store the original const_missing in order to put it back later
		    original_const_missing = begin
			lexical_self.singleton_method(:const_missing)
		    rescue NameError
			nil
		    end

		    # Now inject the method
		    lexical_self.define_singleton_method(:const_missing) do |name|
			if name == grammar_name
			    recursion_wrapper ||= _recursion_wrapper
			elsif original_const_missing
			    original_const_missing.call(name)
			else
			    super
			end
		    end
		end

		subklass = self.new(klass).evaluate(_recursion_wrapper, &block)
		if grammar_name
		    # Restore the original const_missing
		    if original_const_missing
			lexical_self.define_singleton_method(:const_missing, original_const_missing)
		    else
			lexical_self.singleton_class.send(:undef_method, :const_missing) rescue nil
		    end

		    # If the recursion wrapper was generated, then the block must have used it, therefore subklass is recursive
		    if recursion_wrapper
			subklass = post_evaluate(klass, subklass, recursion_wrapper)
		    end

		    # Find the *actual* enclosing scope to assign the resulting constant to. If block was
		    #  created inside of a module that was created with Module.new, then this will be the created
		    #  module. Otherwise, it will end up being the same as lexical_self, but that's fine because in
		    #  that case that's where the new constant needs to go anyway.
		    enclosing_module = eval("self", block.binding)
		    enclosing_module.const_set(grammar_name, subklass)
		else
		    # Finalize the recursion proxy in case it was used
		    if block.arity.nonzero?
			subklass = post_evaluate(klass, subklass, _recursion_wrapper)
		    end

		    subklass
		end
	    else
		raise ArgumentError.new("Block or elements, but not both") if elements.empty?
		klass.with(*elements)
	    end
	end

	def self.post_evaluate(klass, subklass, recursion_wrapper)
	    case klass
		# Convert recursive Alternations into Repetitions
		when Grammar::Alternation
		    original_length = subklass.elements.length
		    non_recursive_elements = subklass.elements.reject {|element| element == recursion_wrapper }

		    if original_length == non_recursive_elements.length
			# Partition the elements into left-recursive and not left-recursive
			left_recursive_elements, other_elements = subklass.elements.partition do |element|
			    (element == recursion_wrapper) or (element.respond_to?(:left_recursive?) and element.left_recursive?)
			end

			# Create an Alternation to contain the non-recursive elements, unless there's only one
			if other_elements.length == 1
			    non_left_recursive_alternation = other_elements.first
			else
			    non_left_recursive_alternation = Grammar::Alternation.with(*other_elements)
			end

			# Create the base for trailing repetition
			repeater_elements = left_recursive_elements.map {|element| element.drop(1)}
			if repeater_elements.length > 1
			    repeater_klass = Grammar::Alternation.with(*repeater_elements)
			elsif repeater_elements.length == 1
			    repeater_klass = repeater_elements.first
			else
			    # Either all of the elements are non-recursive, or they aren't left-recursive
			end

			# Replace the initial subklass with the new "fixed" version
			if repeater_elements.empty?
			    recursion_wrapper.grammar = subklass
			else
			    recursion_wrapper.grammar = Grammar::Concatenation.with(non_left_recursive_alternation, repeater_klass.any)
			end
			recursion_wrapper.freeze
		    else
			subklass.elements.replace(non_recursive_elements)
			Grammar::Repetition.at_least(1, subklass)
		    end

		when Grammar::Concatenation
		    if (subklass.first == recursion_wrapper) and (subklass.last == recursion_wrapper)
			# Outer-recursive - There's nothing to do here for now, just assign the constant
			recursion_wrapper.grammar = subklass
			recursion_wrapper.freeze
		    elsif subklass.first == recursion_wrapper
			# Left-recursive
			subklass.elements.replace(subklass.elements.drop(1))
			subklass = subklass.first if subklass.elements.length == 1
			Grammar::Repetition.any(subklass)
		    elsif subklass.last == recursion_wrapper
			# Right-recursive
			subklass.elements.replace(subklass.elements.slice(0...-1))
			subklass = subklass.first if subklass.elements.length == 1
			Grammar::Repetition.at_least(1, (subklass))
		    elsif subklass.include?(recursion_wrapper)
			# Center-recursive
			recursion_wrapper.grammar = subklass
			recursion_wrapper.freeze
		    elsif subklass.recursive?
			# Somehow, some way, this thing is recursive. It's probably indirect-recursive or mutual-recursive.
			recursion_wrapper.grammar = subklass
			recursion_wrapper.freeze
		    else
			raise StandardError.new("Unknown recursion in Concatenation")
		    end

	 	else
		    recursion_wrapper.grammar = subklass
		    recursion_wrapper.freeze
	    end
	end
    end
end