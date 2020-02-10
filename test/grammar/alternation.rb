require 'grammar/alternation'
require 'grammar/concatenation'

require 'support/equality'
require 'support/repeatable'

RSpec.describe Grammar::Alternation do
    it_should_behave_like 'equality'
    it_should_behave_like 'repeatable'

    it 'must stringify' do
	expect(Grammar::Alternation.to_s).to eq('Grammar::Alternation')
    end

    it 'must subclass with Strings' do
	alternation = Grammar::Alternation.with('abc', 'def', 'xyz')
	expect(alternation.elements.length).to eq(3)
    end

    it 'must be a superclass of its subclasses' do
	expect(Grammar::Alternation).to be > Grammar::Alternation.with('abc', 'def', 'xyz')
	expect(Grammar::Alternation).to be >= Grammar::Alternation.with('abc', 'def', 'xyz')
    end

    it 'must not destructure' do
	expect(Grammar::Alternation.to_a).to be_nil
    end

    it 'must not splat' do
	expect(*Grammar::Alternation).to eq(Grammar::Alternation)
    end

    describe 'when subclassed' do
	subject(:klass) { Grammar::Alternation.with('abc', 'def', 'xyz') }

	it 'must be Enumerable' do
	    expect(klass.to_a).to eq(['abc', 'def', 'xyz'])
	end

	it 'must be a subclass of Alternation' do
	    expect(klass).to be < Grammar::Alternation
	    expect(klass).to be <= Grammar::Alternation
	end

	it 'must destructure' do
	    expect(klass.to_a).to eq(['abc', 'def', 'xyz'])
	end

	it 'must splat' do
	    expect([*klass]).to eq(['abc', 'def', 'xyz'])
	end

	describe 'when directly left recursive' do
	    subject(:klass) do
		recursion = Grammar::Recursion.new()
		recursion.grammar = Grammar::Alternation.with('xyz', recursion, 'abc')
		recursion.grammar
	    end

	    it { should be_left_recursive }

	    it 'must be left-recursive with respect to itself' do
		should be_left_recursive(klass)
	    end

	    it 'must not be left-recursive with respect to anything else' do
		should_not be_left_recursive(Grammar::Concatenation.with('sf'))
	    end
	end

	context Grammar::Recursion do
	    let(:wrapper) { Grammar::Recursion.new }

	    it 'must be recursive when directly recursive' do
		wrapper.grammar = Grammar::Alternation.with('abc', wrapper, 'xyz')
		expect(wrapper.grammar).to be_recursive
	    end

	    it 'must be left-recursive when directly recursive' do
		wrapper.grammar = Grammar::Alternation.with('abc', wrapper, 'xyz')
		expect(wrapper.grammar).to be_left_recursive
	    end

	    it 'it must be recursive when indirectly recursive' do
		wrapper.grammar = Grammar::Alternation.with('abc', Grammar::Concatenation.with('def', wrapper), 'xyz')
		expect(wrapper.grammar).to be_recursive
	    end

	    it 'it must not be left recursive when indirectly recursive' do
		wrapper.grammar = Grammar::Alternation.with('abc', Grammar::Concatenation.with('def', wrapper), 'xyz')
		expect(wrapper.grammar).not_to be_left_recursive
	    end

	    it 'it must be left recursive when indirectly left recursive' do
		wrapper.grammar = Grammar::Alternation.with('abc', Grammar::Concatenation.with(wrapper, 'def'), 'xyz')
		expect(wrapper.grammar).to be_left_recursive
	    end
	end
    end

    it 'must compose with another Alternation' do
	alternation0 = Grammar::Alternation.with('abc', 'def', 'ghi')
	alternation1 = Grammar::Alternation.with('jkl', 'mno')
	alternation = alternation0 | alternation1
	expect(alternation.elements.length).to eq(4)
    end

    it 'must compose with a Concatenation' do
	alternation0 = Grammar::Alternation.with('abc', 'def', 'ghi')
	concatenation = Grammar::Concatenation.with('jkl', 'mno')
	alternation = alternation0 | concatenation
	expect(alternation.elements.length).to eq(4)
    end

    describe 'when converting to a Regexp' do
	it 'must not parenthesize with only a single element' do
	    expect(Grammar::Alternation.with('a').to_regexp).to eq(/a/)
	end

	it 'must convert characters' do
	    expect(Grammar::Alternation.with('a', 'b', 'c').to_regexp).to eq(/(a|b|c)/)
	end

	it 'must convert Strings' do
	    expect(Grammar::Alternation.with('abc', 'def', 'xyz').to_regexp).to eq(/(abc|def|xyz)/)
	end

	it 'must convert regular expressions' do
	    expect(Grammar::Alternation.with(/abc/, /def/, /xyz/).to_regexp).to eq(/((?-mix:abc)|(?-mix:def)|(?-mix:xyz))/)
	end

	it 'must convert nested Alternations' do
	    klass_abc = Grammar::Alternation.with('abc')
	    klass_def = Grammar::Alternation.with('def')
	    klass_xyz = Grammar::Alternation.with('xyz')
	    expect(Grammar::Alternation.with(klass_abc, klass_def, klass_xyz).to_regexp).to eq(/(abc|def|xyz)/)
	end
    end

    describe 'when initializing an instance' do
	subject { Grammar::Alternation.with('abc', 'def') }

	it 'must accept the correct number of arguments' do
	    expect { subject.new('abc', location:0) }.not_to raise_error
	end

	it 'must require the correct number of arguments' do
	    expect { subject.new }.to raise_error(ArgumentError)
	    expect { subject.new('abc', 'def', location:0) }.to raise_error(ArgumentError)
	end

	it 'must not require a location' do
	    expect { subject.new('abc') }.not_to raise_error
	end
    end

    describe 'when an instance' do
	subject(:klass) { Grammar::Alternation.with('abc', 'abcd') }

	it 'must have a length' do
	    expect(klass.new('abc').length).to eq(3)
	    expect(klass.new('abcd').length).to eq(4)
	end

	it 'must destructure' do
	    expect(klass.new('abc').to_a).to eq(['abc'])
	end

	it 'must splat' do
	    expect(*klass.new('abc')).to eq('abc')
	end

	context 'Generic Equality' do
	    let(:klass) { Grammar::Alternation.with('abc', 'def') }

	    it 'must be equal to an equal instance' do
		expect(klass.new('def', location:1)).to eq(klass.new('def', location:1))
	    end
	end
    end
end
