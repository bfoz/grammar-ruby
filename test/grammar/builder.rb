require_relative '../../lib/grammar/builder'

RSpec.describe Grammar::Builder do
    context 'Alternation' do
	subject { Grammar::Builder.new(Grammar::Alternation) }

	it 'must build an Alternation' do
	    klass = subject.evaluate do
		element 'b'
		element 'a'
	    end

	    expect(klass).to be < Grammar::Alternation
	    expect(klass.elements).to eq(['b', 'a'])
	end

	it 'must build a nested Alternation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element alternation { elements 'c', 'd' }
	    end

	    expect(klass).to be < Grammar::Alternation
	    expect(klass.elements.last).to be < Grammar::Alternation
	    expect(klass.elements). to eq(['a', 'b', Grammar::Alternation.with('c', 'd')])
	end

	it 'must build a nested Concatenation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element concatenation { elements 'c', 'd' }
	    end

	    expect(klass).to be < Grammar::Alternation
	    expect(klass.elements.last).to be < Grammar::Concatenation
	    expect(klass.elements). to eq(['a', 'b', Grammar::Concatenation.with('c', 'd')])
	end

	it 'must build a nested repeated Alternation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element alternation { elements 'c', 'd' }.any
	    end

	    expect(klass).to be < Grammar::Alternation
	    expect(klass.elements.last).to be < Grammar::Repetition
	    expect(klass.elements). to eq(['a', 'b', Grammar::Alternation.with('c', 'd').any])
	end

	it 'must build a nested repeated Concatenation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element concatenation { elements 'c', 'd' }.any
	    end

	    expect(klass).to be < Grammar::Alternation
	    expect(klass.elements.last).to be < Grammar::Repetition
	    expect(klass.elements). to eq(['a', 'b', Grammar::Concatenation.with('c', 'd').any])
	end

	it 'must create a Latch' do
	    klass = subject.evaluate do
	    	latch(:foo) { 'foo' }
	    	element 'a'
	    	element 'b'
	    end

	    expect(klass).to be < Grammar::Alternation
	    expect(klass.elements).to eq(['a', 'b'])
	    expect(klass.context.keys.first).to be < Grammar::Latch
	end
    end

    context 'Concatenation' do
	subject { Grammar::Builder.new(Grammar::Concatenation) }

	it 'must build a Concatenation' do
	    klass = subject.evaluate do
		element 'b'
		element 'a'
	    end

	    expect(klass).to be < Grammar::Concatenation
	    expect(klass.elements).to eq(['b', 'a'])
	end

	it 'must build a nested Alternation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element alternation { elements 'c', 'd' }
	    end

	    expect(klass).to be < Grammar::Concatenation
	    expect(klass.elements.last).to be < Grammar::Alternation
	    expect(klass.elements). to eq(['a', 'b', Grammar::Alternation.with('c', 'd')])
	end

	it 'must build a nested Concatenation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element concatenation { elements 'c', 'd' }
	    end

	    expect(klass).to be < Grammar::Concatenation
	    expect(klass.elements.last).to be < Grammar::Concatenation
	    expect(klass.elements). to eq(['a', 'b', Grammar::Concatenation.with('c', 'd')])
	end

	it 'must build a nested repeated Alternation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element alternation { elements 'c', 'd' }.any
	    end

	    expect(klass).to be < Grammar::Concatenation
	    expect(klass.elements.last).to be < Grammar::Repetition
	    expect(klass.elements). to eq(['a', 'b', Grammar::Alternation.with('c', 'd').any])
	end

	it 'must build a nested repeated Concatenation' do
	    klass = subject.evaluate do
		element 'a'
		element 'b'
		element concatenation { elements 'c', 'd' }.any
	    end

	    expect(klass).to be < Grammar::Concatenation
	    expect(klass.elements.last).to be < Grammar::Repetition
	    expect(klass.elements). to eq(['a', 'b', Grammar::Concatenation.with('c', 'd').any])
	end

	it 'must create a Latch' do
	    klass = subject.evaluate do
	    	latch(:foo) { 'foo' }
	    	element 'a'
	    	element 'b'
	    end

	    expect(klass).to be < Grammar::Concatenation
	    expect(klass.elements).to eq(['a', 'b'])
	    expect(klass.context.keys.first).to be < Grammar::Latch
	end
    end
end
