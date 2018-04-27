require 'grammar/alternation'
require 'grammar/concatenation'

RSpec.describe Grammar::Alternation do
    it 'must subclass with Strings' do
	alternation = Grammar::Alternation.with('abc', 'def', 'xyz')
	expect(alternation.elements.length).to eq(3)
    end

    context 'class equality' do
	it 'must be equal to an equal Alternation' do
	    expect(Grammar::Alternation.with('a', 'b')).to eq(Grammar::Alternation.with('a', 'b'))
	end

	it 'must not be equal to an unequal Alternation' do
	    expect(Grammar::Alternation.with('a', 'b')).not_to eq(Grammar::Alternation.with('x', 'y'))
	end

	it 'must not be equal to another Grammar class' do
	    expect(Grammar::Alternation.with('a', 'b')).not_to eq(Grammar::Concatenation.with('a', 'b'))
	end
    end

    context 'class case equality' do
	it 'must be case-equal to the Grammar::Alternation Class' do
	    expect(Grammar::Alternation.with).to be === Grammar::Alternation
	    expect(Grammar::Alternation).to be === Grammar::Alternation.with
	end

	it 'must not be case-equal to another Grammar Class' do
	    expect(Grammar::Alternation.with).not_to be === Grammar::Concatenation
	    expect(Grammar::Alternation).not_to be === Grammar::Concatenation.with
	end

	it 'must not be case-equal to the String class' do
	    expect(Grammar::Alternation.with).not_to be === String
	end

	it 'must not be case-equal to a String' do
	    expect(Grammar::Alternation.with).not_to be === 'a'
	end
    end

    context 'class hash equality' do
	it 'must replace itself in a Hash' do
	    klass = Grammar::Alternation.with('a', 'b')
	    expect(klass).to eql(klass)
	    expect(Grammar::Alternation.with('a', 'b')).to eql(Grammar::Alternation.with('a', 'b'))
	end

	it 'must not replace anything else' do
	    klassA = Grammar::Alternation.with('a', 'b')
	    klassB = Grammar::Alternation.with('a'..'z')
	    expect(klassA).not_to eql(klassB)
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
	it 'must have a length' do
	    expect(Grammar::Alternation.with('abc', 'abcd').new('abc').length).to eq(3)
	    expect(Grammar::Alternation.with('abc', 'abcd').new('abcd').length).to eq(4)
	end

	it 'must be equal to an equal instance' do
	    klass = Grammar::Alternation.with('abc', 'def')
	    expect(klass.new('abc', location:1)).to eq(klass.new('abc', location:1))
	    expect(klass.new('def', location:1)).to eq(klass.new('def', location:1))
	end

	it 'must equal an instance at a different location' do
	    klass = Grammar::Alternation.with('abc', 'def')
	    expect(klass.new('abc', location:0)).to eq(klass.new('abc', location:1))
	end

	it 'must hash-equal an instance at the same location' do
	    klass = Grammar::Alternation.with('abc', 'def')
	    expect(klass.new('abc', location:1)).to eq(klass.new('abc', location:1))
	end

	it 'must not hash-equal an instance at a different location' do
	    klass = Grammar::Alternation.with('abc', 'def')
	    expect(klass.new('abc', location:0)).not_to eql(klass.new('abc', location:1))
	end

	it 'must not equal an unequal match' do
	    klass = Grammar::Alternation.with('abc', 'def')
	    expect(klass.new('abc', location:1)).not_to eq(klass.new('ghi', location:1))
	end

	it 'must not equal anything else' do
	    klass = Grammar::Alternation.with('abc', 'def')
	    expect(klass.new('abc')).not_to eq(Grammar::Concatenation.with('abcdef').new('abcdef'))
	end
    end
end
