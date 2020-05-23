RSpec.shared_examples 'equality' do
    subject(:grammar_klass) { described_class }

    def case_klass(klass, *args)
	_index = [Grammar::Alternation, Grammar::Concatenation, Grammar::Latch, Grammar::Repetition].find_index(&klass.method(:equal?))
	raise ArgumentError.new("Unknown Grammar Type") unless _index
	arg = args[_index]
	arg.respond_to?(:call) ? arg.call : arg
    end

    let!(:different_klass) { case_klass(grammar_klass, Grammar::Concatenation, Grammar::Alternation, Grammar::Alternation, Grammar::Alternation) }

    def create_instance(klass, subklass, location:nil)
	case_klass(klass,
	    ->{ subklass.new('a', location:location) },			# Grammar::Alternation
	    ->{ subklass.new('abc', 'def', location:location) },	# Grammar::Concatenation
	    ->{ location&.zero? ? unequal_subklass.new() : latch_instance },	# Grammar::Latch
	    ->{ subklass.new('a', location:location) },			# Grammar::Repetition
	)
    end

    def create_subclass(klass)
	case_klass(klass,
	    ->{ Grammar::Alternation.with('a', 'b') },
	    ->{ Grammar::Concatenation.with('abc', 'def') },
	    ->{ Grammar::Latch.with('a') },
	    ->{ Grammar::Repetition.any('a') },
	)
    end

    let!(:subklass) { create_subclass(grammar_klass) }
    let(:equal_subklass) { create_subclass(grammar_klass) }

    let(:unequal_subklass) do
	case_klass(grammar_klass,
	    ->{ Grammar::Alternation.with('x', 'y') },
	    ->{ Grammar::Concatenation.with('x', 'y', 'z') },
	    ->{ Grammar::Latch.with('b') },
	    ->{ Grammar::Repetition.any('z') },
	)
    end

    let(:latch_instance) { subklass.new }
    let!(:match_instance) { create_instance(grammar_klass, subklass) }

    # An instance of the subclass that isn't the match_instance but is identical to it
    let(:equal_instance) { create_instance(grammar_klass, subklass) }

    # An instance of the subclass that's identical to the match_instance but at a different location
    let(:equal_instance_different_location) { create_instance(grammar_klass, subklass, location:42) }
    let(:unequal_instance_different_location) { create_instance(grammar_klass, subklass, location:0) }

    # An instance of the subklass that isn't the equal_instance
    let(:unequal_instance) do
	case_klass(grammar_klass,
	    ->{ subklass.new('def', location:1) },					# Grammar::Alternation
	    ->{ subklass.new('def', 'abc') },						# Grammar::Concatenation: NOTE: This is Bad because initialize() should really be checking the passed elements
	    ->{ unequal_subklass.new() },						# Grammar::Latch
	    ->{ subklass.new('a', 'a') },						# Grammar::Repetition
	)
    end

    let(:equal_string) { case_klass(grammar_klass, 'a', 'abcdef', ->{ latch_instance }, 'a') }
    let(:unequal_string) { case_klass(grammar_klass, 'z', 'xyz', false, 'z') }

    context 'Generic Equality' do
	# Class

	it 'must be equal to itself' do
	    is_expected.to eq(grammar_klass)
	end

	it 'must not be equal to another Grammar class' do
	    expect(grammar_klass).not_to eq(different_klass)
	end

	# Subclass

	it 'must not be equal to a subclass' do
	    expect(grammar_klass).not_to eq(subklass)
	end

	# Instance

	it 'must not be equal to an instance' do
	    expect(grammar_klass).not_to eq(match_instance)
	end
    end

    context 'Case Equality' do
	# Class

	it 'must be case-equal to itself' do
	    expect(grammar_klass).to be === grammar_klass
	end

	it 'must not be case-equal to another Grammar class' do
	    expect(grammar_klass).not_to be === different_klass
	end

	# Subclass

	it 'must be case-equal to a subclass' do
	    expect(grammar_klass).to be === subklass
	end

	# Instance

	it 'must be case-equal to an instance' do
	    # This behavior matches Struct === Struct.new(:foo).new(42)
	    expect(grammar_klass).to be === match_instance
	end

	# String

	it 'must not be case-equal to the String class' do
	    expect(grammar_klass).not_to be === String
	end

	it 'must not be case-equal to a string' do
	    expect(grammar_klass).not_to be === 'abc'
	end
    end

    context 'Hash equality' do
	# Class

	it 'must be hash-equal to itself' do
	    expect(grammar_klass).to eql(grammar_klass)
	end

	it 'must not be hash-equal to another Grammar class' do
	    expect(grammar_klass).not_to eql(different_klass)
	end

	# Subclass

	it 'must not be hash-equal to a subclass' do
	    expect(grammar_klass).not_to eql(subklass)
	end
    end

    describe 'when subclassed' do
    	subject { subklass }

	context 'Generic Equality' do
	    # Class

	    it 'must not be equal to the super class' do
		is_expected.not_to eq(grammar_klass)
	    end

	    # Subclass

	    it 'must be equal to itself' do
		is_expected.to eq(subklass)
	    end

	    it 'must be equal to an equal subclass' do
		is_expected.to eq(equal_subklass)
	    end

	    it 'must not be equal to an unequal subclass' do
		is_expected.not_to eq(unequal_subklass)
	    end

	    it 'must not be equal to another Grammar subclass' do
		is_expected.not_to eq(different_klass.with)
	    end
	end

	context 'Case Equality' do
	    # Class

	    it 'must be case-equal to the super class' do
		is_expected.to be === grammar_klass
	    end

	    # Subclass

	    it 'must be case-equal to itself' do
		is_expected.to be === subklass
	    end

	    it 'must be case-equal to an identical subclass' do
		is_expected.to be === equal_subklass
	    end

	    it 'must not be case-equal to a different subclass' do
		is_expected.not_to be === unequal_subklass
	    end

	    # Instance

	    it 'must be case-equal to an instance' do
		# This behavior matches klass = Struct.new(:foo); klass === klass.new(42)
		is_expected.to be === match_instance
	    end

	    # String

	    it 'must not be case-equal to a string' do
		is_expected.not_to be === 'a'
	    end
	end

	context 'Hash Equality' do
	    # Class

	    it 'must not be hash-equal to the super class' do
		is_expected.not_to eql(grammar_klass)
	    end

	    # Subclass

	    it 'must be hash-equal to itself' do
	    	is_expected.to eql(subklass)
	    end

	    it 'must be hash-equal to an identical subclass' do
		is_expected.to eql(equal_subklass)
	    end

	    it 'must not be hash-equal to a different subclass' do
		is_expected.not_to eql(unequal_subklass)
	    end
	end
    end

    describe 'when an instance' do
	subject { match_instance }

	context 'Generic Equality' do
	    # Instance

	    it 'must be equal to an equal instance' do
		is_expected.to eq(equal_instance)
	    end

	    it 'must equal an instance at a different location' do
		is_expected.to eq(equal_instance_different_location)
	    end

	    it 'must not equal an unequal instance' do
		is_expected.not_to eq(unequal_instance)
	    end

	    # String

	    it 'must equal a matching String' do
		is_expected.to eq(equal_string)
	    end

	    it 'must not equal a nonmatching string' do
		is_expected.not_to eq(unequal_string)
	    end
	end

	context 'Case Equality' do
	    # Class

	    it 'must not be case-equal to the super class' do
		is_expected.not_to be === grammar_klass
	    end

	    # Subclass

	    it 'must not be case-equal to its subclass' do
		is_expected.not_to be === subklass
	    end

	    it 'must not be case-equal to an identical subclass' do
	    	is_expected.not_to be === equal_subklass
	    end

	    it 'must not be case-equal to a different subclass' do
		is_expected.not_to be === unequal_subklass
	    end

	    # Instance

	    it 'must be case-equal to itself' do
		is_expected.to be === match_instance
	    end

	    it 'must be case-equal to an equal instance' do
		is_expected.to be === equal_instance
	    end

	    it 'must not be case-equal to a different instance' do
		is_expected.not_to be === unequal_instance
	    end

	    # String

	    it 'must not be case-equal to a string' do
		is_expected.not_to be === 'a'
	    end
	end

	context 'Hash Equality' do
	    # Instance

	    it 'must hash-equal an instance at the same location' do
		is_expected.to eq(equal_instance)
	    end

	    it 'must not hash-equal an instance at a different location' do
		is_expected.not_to eql(unequal_instance_different_location)
	    end
	end
    end
end
