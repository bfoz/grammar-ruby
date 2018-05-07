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
    end
end