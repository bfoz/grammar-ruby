require 'grammar/latch'

require 'support/equality'
require 'support/repeatable'

RSpec.describe Grammar::Latch do
    it_should_behave_like 'equality'
    it_should_behave_like 'repeatable'

    context 'Subclass' do
	it 'must be optional when the target is optional' do
	    expect(Grammar::Latch.with('abc')).not_to be_optional
	    expect(Grammar::Latch.with(Grammar::Concatenation.with('abc').optional)).to be_optional
	end
    end
end
