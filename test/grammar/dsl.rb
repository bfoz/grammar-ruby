require 'grammar/dsl'

RSpec.describe Grammar::DSL do
    let(:test_module) do
	Module.new.tap {|m| m.extend(Grammar::DSL)}
    end

    it 'must create a Module' do
	module Test
	    using Grammar::DSL
	    Rule = alternation('a', 'b')
	end

	expect(Test::Rule).to eq(Grammar::Alternation.with('a', 'b'))
    end

    it 'must not expose the build method to modules' do
	expect do
	    module Test
		using Grammar::DSL
		build()
	    end
	end.to raise_error(NoMethodError)
    end

    it 'must not expose the build method to classes' do
	class TestClass
	    include Grammar::DSL
	end
	expect { TestClass.build }.to raise_error(NoMethodError)
	expect { TestClass.new.build }.to raise_error(NoMethodError)
    end

    context 'Alternation' do
	it 'must build a simple Alternation without a block' do
	    klass = test_module.module_eval do
		alternation 'abc', 'def'
	    end
	    expect(klass).to eq(Grammar::Alternation.with('abc', 'def'))
	end

	it 'must build a simple Alternation with a block' do
	    klass = test_module.module_eval do
		alternation do
		    element 'abc'
		    element 'def'
		end
	    end
	    expect(klass).to eq(Grammar::Alternation.with('abc', 'def'))
	end

	it 'must build a simple Alternation with a block and a name' do
	    test_module.module_eval do
		alternation :Rule do
		    element 'abc'
		    element 'def'
		end
	    end
	    expect(test_module::Rule).to eq(Grammar::Alternation.with('abc', 'def'))
	end
    end

    context 'Concatenation' do
	it 'must build a simple Concatenation without a block' do
	    klass = test_module.module_eval do
		concatenation 'abc', 'def'
	    end
	    expect(klass).to eq(Grammar::Concatenation.with('abc', 'def'))
	end

	it 'must build a simple Concatenation with a block' do
	    klass = test_module.module_eval do
		concatenation do
		    element 'abc'
		    element 'def'
		end
	    end
	    expect(klass).to eq(Grammar::Concatenation.with('abc', 'def'))
	end

	it 'must build a simple Concatenation with a block and a name' do
	    test_module.module_eval do
		concatenation :Rule do
		    element 'abc'
		    element 'def'
		end
	    end
	    expect(test_module::Rule).to eq(Grammar::Concatenation.with('abc', 'def'))
	end
    end

    context 'Recursion' do
	it 'must build a repeating Alternation' do
	    test_module.module_eval do
		alternation(:Rule0) do
		    elements 'abc', 'def', Rule0
		end
	    end
	    expect(test_module::Rule0).to eq(Grammar::Repetition.at_least(1, Grammar::Alternation.with('abc', 'def')))
	end

	it 'must build a left-recursive concatenation' do
	    test_module.module_eval do
		concatenation(:Rule0) do
		    elements Rule0, ')'
		end

		concatenation :Rule1 do
		    elements Rule1, 'abc', 'def'
		end
	    end
	    expect(test_module::Rule0).to eq(Grammar::Repetition.any(')'))
	    expect(test_module::Rule1).to eq(Grammar::Repetition.any(Grammar::Concatenation.with('abc', 'def')))
	end

	it 'must build a right-recursive concatenation' do
	    test_module.module_eval do
		concatenation(:Rule0) do
		    elements '(', Rule0
		end
	    end
	    expect(test_module::Rule0).to eq(Grammar::Repetition.at_least(1, '('))
	end

	it 'must build a center-recursive concatenation' do
	    test_module.module_eval do
		concatenation(:Rule0) do
		    elements '(', Rule0, ')'
		end
	    end
	    expect(test_module::Rule0).to eq(Grammar::Recursion.with(Grammar::Concatenation.with('(', test_module::Rule0, ')')))
	end

	context 'Anonymous Recursion' do
	    it 'must build a repeating Alternation' do
		klass = test_module.module_eval do
		    alternation do |rule0|
			elements 'abc', 'def', rule0
		    end
		end
		expect(klass).to eq(Grammar::Repetition.at_least(1, Grammar::Alternation.with('abc', 'def')))
	    end

	    it 'must build a left-recursive concatenation' do
		klassA = nil
		klassB = nil
		test_module.module_eval do
		    klassA = concatenation do |rule0|
			elements rule0, ')'
		    end

		    klassB = concatenation do |rule1|
			elements rule1, 'abc', 'def'
		    end
		end
		expect(klassA).to eq(Grammar::Repetition.any(')'))
		expect(klassB).to eq(Grammar::Repetition.any(Grammar::Concatenation.with('abc', 'def')))
	    end

	    it 'must build a right-recursive concatenation' do
		klass = test_module.module_eval do
		    concatenation do |rule0|
			elements '(', rule0
		    end
		end
		expect(klass).to eq(Grammar::Repetition.at_least(1, '('))
	    end

	    it 'must build a center-recursive concatenation' do
		klass = test_module.module_eval do
		    concatenation do |rule0|
			elements 'a', rule0, 'z'
		    end
		end
		expect(klass).to eq(Grammar::Recursion.with(Grammar::Concatenation.with('a', klass, 'z')))
	    end
	end

	context 'Mutual Recursion' do
	    it 'must build a mutually recursive Alternation' do
		klassA = nil
		klassB = nil
		test_module.module_eval do
		    alternation :Rule do
			element 'abc'
			element 'def'
			element (klassA = concatenation('xyz', Rule))
			element (klassB = concatenation('uvw', Rule))
		    end
		end

		expect(test_module::Rule).to eq(Grammar::Recursion.with(Grammar::Alternation.with('abc', 'def', klassA, klassB)))
	    end

	    it 'must build a mutually recursive Concatenation' do
		klassA = nil
		klassB = nil
		test_module.module_eval do
		    concatenation :Rule do
			element 'abc'
			element (klassA = concatenation('def', Rule))
			element (klassB = concatenation('uvw', Rule))
			element 'xyz'
		    end
		end

		expect(test_module::Rule).to eq(Grammar::Recursion.with(Grammar::Concatenation.with('abc', klassA, klassB, 'xyz')))
	    end
	end

	context 'Outer Recursion' do
	    it 'must build an outer-recursive concatenation' do
		test_module.module_eval do
		    concatenation :Rule0  do
			elements Rule0, ',', Rule0
		    end
		end
		expect(test_module::Rule0).to eq(Grammar::Recursion.with(Grammar::Concatenation.with(test_module::Rule0, ',', test_module::Rule0)))
	    end

	    it 'must build an Alternation with a nested outer-recursive Concatenation' do
		test_module.module_eval do
		    # This is essentially a list with a separator
		    alternation :Rule0 do
			element 'abc'
			element 'def'
			element concatenation { elements Rule0, ',', Rule0 }
		    end
		end

		expect(test_module::Rule0).to eq(Grammar::Recursion.with(
						    Grammar::Concatenation.with(
							Grammar::Alternation.with('abc', 'def'),
							Grammar::Concatenation.with(',', test_module::Rule0).any
						    )
						 )
						)
	    end

	    it 'must flatten the inner Alternation of an Alternation with a nested outer-recursive Concatenation' do
		test_module.module_eval do
		    # This is essentially a list with a separator
		    alternation :Rule0 do
			element 'abc'
			element concatenation { elements Rule0, ',', Rule0 }
		    end
		end

		expect(test_module::Rule0).to eq(Grammar::Recursion.with(
						    Grammar::Concatenation.with(
							'abc',
							Grammar::Concatenation.with(',', test_module::Rule0).any
						    )
						 )
						)
	    end

	    it 'must build an Alternation with two nested outer-recursive Concatenations' do
		test_module.module_eval do
		    # This is essentially a list with two types of separator
		    alternation :Rule0 do
			element 'abc'
			element 'def'
			element concatenation { elements Rule0, ',', Rule0 }
			element concatenation { elements Rule0, '|', Rule0 }
		    end
		end

		expect(test_module::Rule0).to eq(Grammar::Recursion.with(
						    Grammar::Concatenation.with(
							Grammar::Alternation.with('abc', 'def'),
							Grammar::Alternation.with(
							    Grammar::Concatenation.with(',', test_module::Rule0),
							    Grammar::Concatenation.with('|', test_module::Rule0)
							).any
						    )
						 )
						)
	    end

	    it 'must build a recursive Alternation with a mixture of nested recursions' do
		test_module.module_eval do
		    # This is essentially a list with two types of separator
		    alternation :Rule0 do
			element 'abc'
			element 'def'
			element concatenation { elements '(', Rule0, ')' }
			element concatenation { elements Rule0, ',', Rule0 }
			element concatenation { elements Rule0, '|', Rule0 }
		    end
		end

		expect(test_module::Rule0).to eq(Grammar::Recursion.with(
						    Grammar::Concatenation.with(
							Grammar::Alternation.with('abc', 'def', Grammar::Concatenation.with('(', test_module::Rule0, ')')),
							Grammar::Alternation.with(
							    Grammar::Concatenation.with(',', test_module::Rule0),
							    Grammar::Concatenation.with('|', test_module::Rule0)
							).any
						    )
						 )
						)
	    end
	end
    end

    context 'String refinement' do
	it 'must alternate with other Strings' do
	    module StringTest1
		using Grammar::DSL
		Rule0 = 'abc' | 'def'
	    end

	    expect(StringTest1::Rule0).to eq(Grammar::Alternation.with('abc', 'def'))
	end

	it 'must make Strings repeatable' do
	    module StringTest2
		using Grammar::DSL
		Rule0 = 'abc'.any
	    end

	    expect(StringTest2::Rule0).to eq(Grammar::Repetition.any('abc'))
	end

	it 'must make Strings composable with Alternations' do
	    module StringTest3
		using Grammar::DSL
		Rule0 = '(' + alternation('a', 'b')
	    end
	    expect(StringTest3::Rule0).to eq(Grammar::Concatenation.with('(', Grammar::Alternation.with('a', 'b')))
	end

	it 'must make Strings composable with Concatenations' do
	    module StringTest4
		using Grammar::DSL
		Rule0 = 'a' + concatenation('b', 'c')
	    end
	    expect(StringTest4::Rule0).to eq(Grammar::Concatenation.with('a', 'b', 'c'))
	end

	it 'must not break String addition' do
	    module StringTest5
		using Grammar::DSL
		Rule0 = 'a' + 'b'
	    end
	    expect(StringTest5::Rule0).to eq('ab')
	end
    end
end