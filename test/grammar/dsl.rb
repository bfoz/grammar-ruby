require 'grammar/dsl'

RSpec.describe Grammar::DSL do
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

    context 'Recursion' do
	it 'must build a repeating Alternation' do
	    module Test0
		using Grammar::DSL

		alternation(:Rule0) do
		    elements 'abc', 'def', Rule0
		end
	    end
	    expect(Test0::Rule0).to eq(Grammar::Repetition.at_least(1, Grammar::Alternation.with('abc', 'def')))
	end

	it 'must build a left-recursive concatenation' do
	    module Test1
		using Grammar::DSL

		concatenation(:Rule0) do
		    elements Rule0, ')'
		end

		concatenation :Rule1 do
		    elements Rule1, 'abc', 'def'
		end
	    end
	    expect(Test1::Rule0).to eq(Grammar::Repetition.any(')'))
	    expect(Test1::Rule1).to eq(Grammar::Repetition.any(Grammar::Concatenation.with('abc', 'def')))
	end

	it 'must build a right-recursive concatenation' do
	    module Test2
		using Grammar::DSL

		concatenation(:Rule0) do
		    elements '(', Rule0
		end
	    end
	    expect(Test2::Rule0).to eq(Grammar::Repetition.at_least(1, '('))
	end

	it 'must build a center-recursive concatenation' do
	    module Test3
		using Grammar::DSL

		concatenation(:Rule0) do
		    elements '(', Rule0, ')'
		end
	    end
	    expect(Test3::Rule0).to eq(Grammar::Recursion.with(Grammar::Concatenation.with('(', Test3::Rule0, ')')))
	end

	context 'Outer Recursion' do
	    it 'must build an outer-recursive concatenation' do
		module Test4
		    using Grammar::DSL

		    concatenation :Rule0  do
			elements Rule0, ',', Rule0
		    end
		end
		expect(Test4::Rule0).to eq(Grammar::Recursion.with(Grammar::Concatenation.with(Test4::Rule0, ',', Test4::Rule0)))
	    end

	    it 'must build an Alternation with a nested outer-recursive Concatenation' do
		module Test5
		    using Grammar::DSL

		# This is essentially a list with a separator
		    alternation :Rule0 do
			element 'abc'
			element 'def'
			element concatenation { elements Rule0, ',', Rule0 }
		    end
		end

		expect(Test5::Rule0).to eq(Grammar::Recursion.with(
						Grammar::Concatenation.with(
						    Grammar::Alternation.with('abc', 'def'),
						    Grammar::Concatenation.with(',', Test5::Rule0).any
						)
					   )
					  )
	    end

	    it 'must flatten the inner Alternation of an Alternation with a nested outer-recursive Concatenation' do
		module Test6
		    using Grammar::DSL

		    # This is essentially a list with a separator
		    alternation :Rule0 do
			element 'abc'
			element concatenation { elements Rule0, ',', Rule0 }
		    end
		end

		expect(Test6::Rule0).to eq(Grammar::Recursion.with(
						Grammar::Concatenation.with(
						    'abc',
						    Grammar::Concatenation.with(',', Test6::Rule0).any
						)
					   )
					  )
	    end

	    it 'must build an Alternation with two nested outer-recursive Concatenations' do
		module Test7
		    using Grammar::DSL

		    # This is essentially a list with two types of separator
		    alternation :Rule0 do
			element 'abc'
			element 'def'
			element concatenation { elements Rule0, ',', Rule0 }
			element concatenation { elements Rule0, '|', Rule0 }
		    end
		end

		expect(Test7::Rule0).to eq(Grammar::Recursion.with(
						Grammar::Concatenation.with(
						    Grammar::Alternation.with('abc', 'def'),
						    Grammar::Alternation.with(
							Grammar::Concatenation.with(',', Test7::Rule0),
							Grammar::Concatenation.with('|', Test7::Rule0)
						    ).any
						)
					   )
					  )
	    end

	    it 'must build a recursive Alternation with a mixture of nested recursions' do
		module Test8
		    using Grammar::DSL

		    # This is essentially a list with two types of separator
		    alternation :Rule0 do
			element 'abc'
			element 'def'
			element concatenation { elements '(', Rule0, ')' }
			element concatenation { elements Rule0, ',', Rule0 }
			element concatenation { elements Rule0, '|', Rule0 }
		    end
		end

		expect(Test8::Rule0).to eq(Grammar::Recursion.with(
						Grammar::Concatenation.with(
						    Grammar::Alternation.with('abc', 'def', Grammar::Concatenation.with('(', Test8::Rule0, ')')),
						    Grammar::Alternation.with(
							Grammar::Concatenation.with(',', Test8::Rule0),
							Grammar::Concatenation.with('|', Test8::Rule0)
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