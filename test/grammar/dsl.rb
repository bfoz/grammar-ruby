RSpec.describe Grammar::DSL do
    it 'must create a Module' do
	module Test
	    extend Grammar::DSL
	    Rule = alternation('a', 'b')
	end

	expect(Test::Rule).to eq(Grammar::Alternation.with('a', 'b'))
    end

    it 'must not expose the build method to modules' do
	expect do
	    module Test
		extend Grammar::DSL
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
end