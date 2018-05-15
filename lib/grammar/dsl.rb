require_relative 'recursion'

module Grammar
    module DSL
	def self.build(klass, *elements, &block)
	    if block_given?
		grammar_name = elements.shift if elements.first&.is_a?(Symbol)
		raise ArgumentError("Block or elements, but not both") unless elements.empty?

		if grammar_name
		    recursion_wrapper = nil

		    # If it's stupid and it works, it's not stupid
		    # This injects a const_missing handler into block's lexically enclosing Module for
		    #  the purpose of catching any uses of the not-yet-defined recursive grammar-in-progress.
		    # Any such references are replaced with a Recursion wrapper object
		    enclosing_module = eval("self", block.binding)

		    # But first, store the original const_missing in order to put it back later
		    original_const_missing = begin
			enclosing_module.singleton_method(:const_missing)
		    rescue NameError
			nil
		    end

		    # Now inject the method
		    enclosing_module.define_singleton_method(:const_missing) do |name|
			recursion_wrapper ||= Grammar::Recursion.new if name == grammar_name
		    end
		end

		subklass = Grammar::Builder.new(klass).evaluate(&block)
		if grammar_name
		    # Restore the original const_missing
		    if original_const_missing
			enclosing_module.define_singleton_method(:const_missing, original_const_missing)
		    else
			enclosing_module.singleton_class.send(:undef_method, :const_missing) rescue nil
		    end

		    # If the recursion wrapper was generated, then the block must have used it, therefore subklass is recursive
		    if recursion_wrapper
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
					raise StandardError.new("No recursive elements in a recursive grammar")
				    end

				    # Replace the initial subklass with the new "fixed" version
				    recursion_wrapper.grammar = Grammar::Concatenation.with(non_left_recursive_alternation, repeater_klass.any)
				    enclosing_module.const_set(grammar_name, recursion_wrapper.freeze)
				else
				    subklass.elements.replace(non_recursive_elements)
				    enclosing_module.const_set(grammar_name, Grammar::Repetition.at_least(1, subklass))
				end

			    when Grammar::Concatenation
				if (subklass.first == recursion_wrapper) and (subklass.last == recursion_wrapper)
				    # Outer-recursive - There's nothing to do here for now, just assign the constant
				    recursion_wrapper.grammar = subklass
				    enclosing_module.const_set(grammar_name, recursion_wrapper.freeze)
				elsif subklass.first == recursion_wrapper
				    # Left-recursive
				    subklass.elements.replace(subklass.elements.drop(1))
				    subklass = subklass.first if subklass.elements.length == 1
				    enclosing_module.const_set(grammar_name, Grammar::Repetition.any(subklass))
				elsif subklass.last == recursion_wrapper
				    # Right-recursive
				    subklass.elements.replace(subklass.elements.slice(0...-1))
				    subklass = subklass.first if subklass.elements.length == 1
				    enclosing_module.const_set(grammar_name, Grammar::Repetition.at_least(1, (subklass)))
				elsif subklass.include?(recursion_wrapper)
				    # Center-recursive
				    recursion_wrapper.grammar = subklass
				    enclosing_module.const_set(grammar_name, recursion_wrapper.freeze)
				end
	 		    else
				recursion_wrapper.grammar = subklass
				enclosing_module.const_set(grammar_name, recursion_wrapper.freeze)
			end
		    else
			enclosing_module.const_set(grammar_name, subklass)
		    end
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

	refine Module do
	    include Grammar::DSL
	end
    end
end
