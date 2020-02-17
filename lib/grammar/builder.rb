require 'grammar'

require_relative 'dsl'

module Grammar
    class Builder
	include Grammar::DSL

	def initialize(klass, local_constants={})
	    @elements = []
	    @klass = klass
	    @local_constants = local_constants
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

	# @return [Grammar]	the newly created Grammar element
	def element(arg)
	    if arg.is_a?(Hash) and (arg.length==1) and arg.keys.first.is_a?(Symbol)
		const_name = arg.keys.first
		arg = arg[const_name]
		@local_constants[const_name] = arg
	    end
	    @elements.push arg
	    arg
	end

	def elements(*args)
	    args.each {|arg| self.element(arg) }
	end

	# Wrap the evaluation step to make subclassing easier
	# @return The result of the evaluation
	def self.evaluate(klass, recursion_proxy, local_constants, **options, &block)
	    self.new(klass, local_constants).evaluate(recursion_proxy, &block)
	end

	def self.build(klass, *elements, **options, &block)
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
		local_constants = {}
		lexical_self.define_singleton_method(:const_missing) do |name|
		    if name == grammar_name
			recursion_wrapper ||= _recursion_wrapper
		    elsif local_constants[name]
			local_constants[name]
		    elsif original_const_missing
			original_const_missing.call(name)
		    else
			super(name)	# Can't implictly pass arguments to super when using define_method()
		    end
		end

		subklass = self.evaluate(klass, _recursion_wrapper, local_constants, &block)
		# Restore the original const_missing
		if original_const_missing
		    lexical_self.define_singleton_method(:const_missing, original_const_missing)
		else
		    lexical_self.singleton_class.send(:undef_method, :const_missing) rescue nil
		end

		if grammar_name
		    # If the recursion wrapper was generated, then the block must have used it, therefore subklass is recursive
		    if recursion_wrapper
			subklass = post_evaluate(klass, subklass, recursion_wrapper)
			subklass = subklass.grammar if subklass == recursion_wrapper
		    end

		    # Find the *actual* enclosing scope to assign the resulting constant to. If block was
		    #  created inside of a module that was created with Module.new, then this will be the created
		    #  module. Otherwise, it will end up being the same as lexical_self, but that's fine because in
		    #  that case that's where the new constant needs to go anyway.
		    enclosing_module = eval("self", block.binding)

		    # If the enclosing module is actually another Builder then this grammar_name needs to be set on
		    #  the class that the enclosing Builder is working on, which isn't available yet. So, reach
		    #  into the enclosing Builder and rudely add to its set of local constants that will be added
		    #  to the final class.
		    if enclosing_module.is_a?(self)
			parent_constants = enclosing_module.instance_variable_get(:@local_constants)
			parent_constants[grammar_name] ||= subklass
		    else
			enclosing_module.const_set(grammar_name, subklass)
		    end
		else
		    # Finalize the recursion proxy in case it was used
		    if block.arity.nonzero?
			subklass = post_evaluate(klass, subklass, _recursion_wrapper, require_recursion:false)

			# For anonymous recursion blocks, return the resulting pattern rather than the recursion-proxy
			#  This behavior is closer to that of a non-recursive block and, hopefully, more intuitive
			subklass = subklass.grammar if subklass.is_a?(Grammar::Recursion)
		    end

		    subklass
		end.tap do |_subklass|
		    _subklass = _subklass.grammar if _subklass.respond_to?(:grammar)
		    local_constants.map do |k,v|
			_subklass.const_set(k, v)
		    end
		end
	    else
		elements, local_constants = elements.reduce([[], {}]) do |(_elements, _local_constants), element|
		    if element.is_a?(Hash) and (element.length==1) and element.keys.first.is_a?(Symbol)
			const_name = element.keys.first
			_local_constants[const_name] = element[const_name]
			_elements.push element[const_name]
		    else
			_elements.push element
		    end
		    [_elements, _local_constants]
		end

		if options.empty?
		    klass.with(*elements)
		else
		    klass.with(*elements, **options)
		end.tap do |_klass|
		    local_constants.map do |k,v|
			_klass.const_set(k, v)
		    end
		end
	    end
	end

	def self.post_evaluate(klass, subklass, recursion_wrapper, require_recursion:true)
	    case klass
		# Convert recursive Alternations into Repetitions
		when Grammar::Alternation
		    original_length = subklass.elements.length
		    non_recursive_elements = subklass.elements.reject {|element| element == recursion_wrapper }

		    if original_length == non_recursive_elements.length
			# Partition the elements into left-recursive and not left-recursive
			left_recursive_elements, other_elements = subklass.elements.partition do |element|
			    element.respond_to?(:left_recursive?) and element.left_recursive?(recursion_wrapper)
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
		    elsif subklass.recursive?(recursion_wrapper)
			# Somehow, some way, this thing is recursive. It's probably indirect-recursive or mutual-recursive.
			recursion_wrapper.grammar = subklass
			recursion_wrapper.freeze
		    elsif require_recursion
			raise StandardError.new("Unknown recursion in Concatenation")
		    else
			# If the resulting grammar isn't recursive, and recursion isn't required, then this was probably an
			#  anonymous recursion block that didn't actually use the recursion proxy. So just return the class.
			# But finalize the recursion wrapper anyway, just in case
			recursion_wrapper.grammar = subklass
			recursion_wrapper.freeze
			subklass
		    end

	 	else
		    recursion_wrapper.grammar = subklass
		    recursion_wrapper.freeze
	    end
	end
    end
end
