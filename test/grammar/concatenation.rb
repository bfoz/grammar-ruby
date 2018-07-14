require 'grammar/alternation'
require 'grammar/concatenation'

require 'support/equality'

RSpec.describe Grammar::Concatenation do
    it_should_behave_like 'equality'

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

    context 'class hash equality' do
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
    end
end
