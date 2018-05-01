require 'grammar/alternation'
require 'grammar/concatenation'

RSpec.describe Grammar::Concatenation do
    describe 'when subclassed' do
	it 'must subclass with Strings' do
	    concatenation = Grammar::Concatenation.with('abc', 'def', 'xyz')
	    expect(concatenation.elements.length).to eq(3)
	end

	it 'must be Enumerable' do
	    klass = Grammar::Concatenation.with('abc', 'def', 'xyz')
	    expect(klass.to_a).to eq(['abc', 'def', 'xyz'])
	end
    end

    context 'equality' do
	it 'must be equal to an equal Concatenation' do
	    expect(Grammar::Concatenation.with('a', 'b')).to eq(Grammar::Concatenation.with('a', 'b'))
	end

	it 'must not be equal to an unequal Concatenation' do
	    expect(Grammar::Concatenation.with('a', 'b')).not_to eq(Grammar::Concatenation.with('x', 'y'))
	end

	it 'must not be equal to a Alternation' do
	    expect(Grammar::Concatenation.with('a', 'b')).not_to eq(Grammar::Alternation.with('a', 'b'))
	end
    end

    context 'class case equality' do
	it 'must be case-equal to the Grammar::Concatenation Class' do
	    expect(Grammar::Concatenation.with).to be === Grammar::Concatenation
	    expect(Grammar::Concatenation).to be === Grammar::Concatenation.with
	end

	it 'must not be case-equal to another Grammar Class' do
	    expect(Grammar::Concatenation.with).not_to be === Grammar::Alternation
	    expect(Grammar::Concatenation).not_to be === Grammar::Alternation.with
	end

	it 'must not be case-equal to the String class' do
	    expect(Grammar::Concatenation.with).not_to be === String
	end

	it 'must not be case-equal to a String' do
	    expect(Grammar::Concatenation.with).not_to be === 'a'
	end
    end

    context 'class hash equality' do
	it 'must replace itself in a Hash' do
	    klass = Grammar::Concatenation.with('a', 'b')
	    expect(klass).to eql(klass)
	    expect(Grammar::Concatenation.with('a', 'b')).to eql(Grammar::Concatenation.with('a', 'b'))
	end

	it 'must not replace anything else' do
	    klassA = Grammar::Concatenation.with('a', 'b')
	    klassB = Grammar::Concatenation.with('a'..'z')
	    expect(klassA).not_to eql(klassB)
	end
    end

    context 'composition' do
	it 'must compose with an Alternation' do
	    alternation = Grammar::Alternation.with('abc', 'def', 'ghi')
	    concatenation0 = Grammar::Concatenation.with('jkl', 'mno')
	    concatenation = concatenation0 + alternation
	    expect(concatenation.elements.length).to eq(3)
	end

	it 'must compose with a another Concatenation' do
	    concatenation0 = Grammar::Concatenation.with('abc', 'def', 'ghi')
	    concatenation1 = Grammar::Concatenation.with('jkl', 'mno')
	    concatenation = concatenation0 + concatenation1
	    expect(concatenation.elements.length).to eq(4)
	end
    end

    describe 'when converting to a Regexp' do
	it 'must convert characters' do
	    expect(Grammar::Concatenation.with('a', 'b', 'c').to_regexp).to eq(/abc/)
	end

	it 'must convert Strings' do
	    expect(Grammar::Concatenation.with('abc', 'def', 'xyz').to_regexp).to eq(/abcdefxyz/)
	end

	it 'must convert regular expressions' do
	    expect(Grammar::Concatenation.with(/abc/, /def/, /xyz/).to_regexp).to eq(/(?-mix:abc)(?-mix:def)(?-mix:xyz)/)
	end

	it 'must convert nested Alternations' do
	    klass_abc = Grammar::Alternation.with('abc')
	    klass_def = Grammar::Alternation.with('def')
	    klass_xyz = Grammar::Alternation.with('xyz')
	    expect(Grammar::Concatenation.with(klass_abc, klass_def, klass_xyz).to_regexp).to eq(/abcdefxyz/)
	end

	it 'must convert nested Concatenations' do
	    klass_abc = Grammar::Concatenation.with('abc')
	    klass_def = Grammar::Concatenation.with('def')
	    klass_xyz = Grammar::Concatenation.with('xyz')
	    expect(Grammar::Concatenation.with(klass_abc, klass_def, klass_xyz).to_regexp).to eq(/abcdefxyz/)
	end
    end

    describe 'when initializing an instance' do
    	subject { Grammar::Concatenation.with('abc', 'def') }

	it 'must accept the correct number of arguments' do
	    expect { subject.new('abc', 'def', location:0) }.not_to raise_error
	    expect(subject.new('abc', 'def', location:0).elements).to eq(['abc', 'def'])
	end

	it 'must require the correct number of arguments' do
	    expect { subject.new('abc', location:0) }.to raise_error(ArgumentError)
	end

	it 'must not require a location' do
	    expect { subject.new('abc', 'def') }.not_to raise_error
	end
    end

    describe 'when an instance' do
	it 'must have a length' do
	    klass = Grammar::Concatenation.with('abc', 'def')
	    expect(klass.new('abc', 'def').length).to eq(6)
	end

	it 'must be Enumerable' do
	    klass = Grammar::Concatenation.with('abc', 'def')
	    expect(klass.new('abc', 'def').to_a).to eq(['abc', 'def'])
	end

	context 'equality' do
	    it 'must equal an equal instance' do
		klass = Grammar::Concatenation.with('abc', 'def')
		expect(klass.new('abc', 'def', location:0)).to eq(klass.new('abc', 'def', location:0))
	    end

	    it 'must not equal an unequal instance' do
		klass = Grammar::Concatenation.with('abc', 'def')

		# NOTE This is Bad because initialize() should really be checking the passed elements
		expect(klass.new('abc', 'def', location:0)).not_to eq(klass.new('def', 'abc', location:0))
	    end

	    it 'must equal an instance at a different location' do
		klass = Grammar::Concatenation.with('abc', 'def')
		expect(klass.new('abc', 'def', location:0)).to eq(klass.new('abc', 'def', location:1))
	    end

	    it 'must not equal anything else' do
		klass = Grammar::Concatenation.with('abc', 'def')
		expect(klass.new('abc', 'def', location:1)).not_to eq(Grammar::Alternation.with('abc', 'def').new('abc', location:1))
	    end
	end

	context 'hash equality' do
	    it 'must replace an instance at the same location' do
		klass = Grammar::Concatenation.with('abc', 'def')
		expect(klass.new('abc', 'def', location:1)).to eql(klass.new('abc', 'def', location:1))
	    end

	    it 'must not replace an instance at a different location' do
		klass = Grammar::Concatenation.with('abc', 'def')
		expect(klass.new('abc', 'def', location:0)).not_to eql(klass.new('abc', 'def', location:1))
	    end

	    it 'must not replace anything else' do
		klass = Grammar::Concatenation.with('abc', 'def')
		expect(klass.new('abc', 'def')).not_to eql(Grammar::Alternation.with('abc', 'def').new('abc'))
	    end
	end
    end
end
