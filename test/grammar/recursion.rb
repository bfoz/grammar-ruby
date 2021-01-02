require 'grammar/recursion'

RSpec.describe Grammar::Recursion do
    context 'Subclass' do
	it 'must be optional' do
	    expect(Grammar::Recursion.with('abc')).to be_optional
	end

	it 'must not become more optional' do
	    klass = Grammar::Recursion.with('abc')
	    expect(klass.optional).to equal(klass)
	end

	it 'must be recursive with respect to itself' do
	    klass = Grammar::Recursion.with('abc')
	    expect(klass).to be_recursive(klass)
	end

	it 'must be recursive with respect to the wrapped grammar' do
	    klass = Grammar::Recursion.with('abc')
	    expect(klass).to be_recursive('abc')
	end

	it 'must be left recursive with respect to itself' do
	    klass = Grammar::Recursion.with('abc')
	    expect(klass).to be_left_recursive(klass)
	end

	it 'must be left recursive with respect to the wrapped grammar' do
	    klass = Grammar::Recursion.with('abc')
	    expect(klass).to be_left_recursive('abc')
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

	context 'Hash Equality' do
	    it 'must be hash-equal to itself' do
		expect(klass).to eql(klass)
	    end

	    it 'must be hash-equal to a different instance with the same grammar instance' do
		grammar = Grammar::Concatenation.with('abc')
		expect(Grammar::Recursion.with(grammar)).to eql(Grammar::Recursion.with(grammar))
	    end

	    it 'must be hash-equal to a different instance with an equal grammar' do
		expect(Grammar::Recursion.with(Grammar::Concatenation.with('abc'))).to eql(Grammar::Recursion.with(Grammar::Concatenation.with('abc')))
	    end

	    it 'must not be hash-equal to a different instance with a different grammar' do
		expect(klass).not_to eql(Grammar::Recursion.with(Grammar::Concatenation.with('xyz')))
	    end
	end
    end
end
