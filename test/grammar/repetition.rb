require 'grammar/repetition'

require 'support/equality'

RSpec.describe Grammar::Repetition do
    it_should_behave_like 'equality'

    describe 'when subclassed' do
	it 'must have a maximum' do
	    klass = Grammar::Repetition.at_most(42, 'abc')
	    expect(klass.maximum).to eq(42)
	    expect(klass.minimum).not_to eq(42)
	end

	it 'must have a minimum' do
	    klass = Grammar::Repetition.at_least(42, 'abc')
	    expect(klass.maximum).not_to eq(42)
	    expect(klass.minimum).to eq(42)
	end

	it 'must have one or more' do
	    klass = Grammar::Repetition.one_or_more('abc')
	    expect(klass.maximum).to be_nil
	    expect(klass.minimum).to eq(1)
	end

	it 'must be optional when optional' do
	    klass = Grammar::Repetition.optional('abc')
	    expect(klass.maximum).to eq(1)
	    expect(klass.minimum).to eq(0)
	    expect(klass.optional?).to eq(true)
	end

	it 'must be Enumerable' do
	    klass = Grammar::Repetition.optional('abc')
	    expect(klass.new('abc', 'abc').to_a).to eq(['abc', 'abc'])
	end
    end

    context 'composition' do
	it 'must compose as an Alternation' do
	    expect(Grammar::Repetition.any('a') | Grammar::Repetition.any('z')).to eq(Grammar::Alternation.with(Grammar::Repetition.any('a'), Grammar::Repetition.any('z')))
	end

	it 'must compose as a Concatenation' do
	    expect(Grammar::Repetition.any('a') + Grammar::Repetition.any('z')).to eq(Grammar::Concatenation.with(Grammar::Repetition.any('a'), Grammar::Repetition.any('z')))
	end

	it 'must be nestable' do
	    klass = Grammar::Repetition.optional('a').optional
	    expect(klass).to eq(Grammar::Repetition.optional(Grammar::Repetition.optional('a')))
	end
    end

    describe 'when converting to a Regexp' do
	context 'Alternation' do
	    subject { Grammar::Alternation.with('a', 'b') }

	    it 'must convert a bounded repetition' do
		expect(subject.repeat(2,3).to_regexp).to eq(/(a|b){2,3}/)
	    end

	    it 'must convert an exact repetition' do
		expect(subject.repeat(2,2).to_regexp).to eq(/(a|b){2}/)
		expect(subject.repeat(2).to_regexp).to eq(/(a|b){2}/)
		expect(subject.repeat(1,1).to_regexp).to eq(/(a|b)/)
	    end

	    it 'must convert an at_least repetition' do
		expect(subject.at_least(2).to_regexp).to eq(/(a|b){2,}/)
		expect(subject.at_least(1).to_regexp).to eq(/(a|b)+/)
	    end

	    it 'must convert an at_most repetition' do
		expect(subject.at_most(2).to_regexp).to eq(/(a|b){,2}/)
		expect(subject.at_most(1).to_regexp).to eq(/(a|b)?/)
	    end

	    it 'must convert a one_or_more repetition' do
		expect(subject.one_or_more.to_regexp).to eq(/(a|b)+/)
	    end

	    it 'must convert an optional' do
		expect(subject.optional.to_regexp).to eq(/(a|b)?/)
	    end
	end

	context 'Concatenation' do
	    subject { Grammar::Concatenation.with('a', 'b') }

	    it 'must convert a bounded repetition' do
		expect(subject.repeat(2,3).to_regexp).to eq(/(ab){2,3}/)
	    end

	    it 'must convert an exact repetition' do
		expect(subject.repeat(2,2).to_regexp).to eq(/(ab){2}/)
		expect(subject.repeat(2).to_regexp).to eq(/(ab){2}/)
		expect(subject.repeat(1,1).to_regexp).to eq(/ab/)
	    end

	    it 'must convert an at_least repetition' do
		expect(subject.at_least(2).to_regexp).to eq(/(ab){2,}/)
		expect(subject.at_least(1).to_regexp).to eq(/(ab)+/)
	    end

	    it 'must convert an at_most repetition' do
		expect(subject.at_most(2).to_regexp).to eq(/(ab){,2}/)
		expect(subject.at_most(1).to_regexp).to eq(/(ab)?/)
	    end

	    it 'must convert a one_or_more repetition' do
		expect(subject.one_or_more.to_regexp).to eq(/(ab)+/)
	    end

	    it 'must convert an optional' do
		expect(subject.optional.to_regexp).to eq(/(ab)?/)
	    end
	end
    end
end
