RSpec.shared_examples 'repeatable' do
    subject(:grammar_klass) { described_class }

    def case_klass(klass, *args)
	_index = [Grammar::Alternation, Grammar::Concatenation].find_index(&klass.method(:equal?))
	raise ArgumentError.new("Unknown Grammar Type: #{klass}") unless _index
	arg = args[_index]
	arg.respond_to?(:call) ? arg.call : arg
    end

    def create_subclass(klass)
	case_klass(klass,
	    ->{ Grammar::Alternation.with('a', 'b') },
	    ->{ Grammar::Concatenation.with('abc', 'def') },
	)
    end

    let!(:subklass) { create_subclass(grammar_klass) }

    describe 'when subclassed' do
	it 'must any' do
	    expect(subklass.any).to eq(Grammar::Repetition.any(subklass))
	end

	it 'must at_least' do
	    expect(subklass.at_least(1)).to eq(Grammar::Repetition.at_least(1, subklass))
	end

	it 'must at_most' do
	    expect(subklass.at_most(42)).to eq(Grammar::Repetition.at_most(42, subklass))
	end

	it 'must less_than' do
	    expect(subklass.less_than(42)).to eq(Grammar::Repetition.less_than(42, subklass))
	end

	it 'must more_than' do
	    expect(subklass.more_than(42)).to eq(Grammar::Repetition.more_than(42, subklass))
	end

	it 'must one' do
	    expect(subklass.one).to eq(Grammar::Repetition.one(subklass))
	end

	it 'must one_or_more' do
	    expect(subklass.one_or_more).to eq(Grammar::Repetition.one_or_more(subklass))
	end

	it 'must optional' do
	    expect(subklass.optional).to eq(Grammar::Repetition.optional(subklass))
	end

	it 'must repeat' do
	    expect(subklass.repeat(5)).to eq(Grammar::Repetition.repeat(subklass, 5))
	    expect(subklass.repeat(5, 42)).to eq(Grammar::Repetition.repeat(subklass, 5, 42))
	end
    end
end
