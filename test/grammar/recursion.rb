require 'grammar/recursion'

RSpec.describe Grammar::Recursion do
    context 'Subclass' do
	it 'must be optional' do
	    expect(Grammar::Recursion.with('abc')).to be_optional
	end
    end

    context 'when an instance' do
	subject(:klass) { Grammar::Recursion.with('abc') }

	it 'must be equal to itself' do
	    expect(klass).to eq(klass)
	end

	it 'must not be equal to a different instance with a different grammar' do
	    expect(klass).not_to eq(Grammar::Recursion.with('xyz'))
	end
    end
end
