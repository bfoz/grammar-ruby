require_relative 'repetition'

# Inspired by the great Jim Weirich's 're' gem (http://github.com/jimweirich/re)
module Grammar::Repeatable
    # Zero or more repetitions
    # @return [Repetition]
    def any
	Grammar::Repetition.any(self)
    end
    alias zero_or_more any

    # @param min [Integer]  The minimum number of repetitions to accept
    # @return [Repetition]
    def at_least(minimum)
	Grammar::Repetition.at_least(minimum, self)
    end

    # @param [Integer]  The maximum number of repetitions to accept (inclusive)
    # @return [Repetition]
    def at_most(maximum)
	Grammar::Repetition.at_most(maximum, self)
    end

    # @param [Integer]  Accept up to, but not including, maximum repetitions
    # @return [Repetition]
    def less_than(maximum)
	Grammar::Repetition.less_than(maximum, self)
    end

    # @param [Integer]  Accept more than minimum repetitions
    # @return [Repetition]
    def more_than(minimum)
	Grammar::Repetition.more_than(minimum, self)
    end

    # Require at least one repetition
    # @return [Repetition]
    def one_or_more
	Grammar::Repetition.one_or_more(self)
    end

    # Require exactly 0 or 1 instances
    # @return [Repetition]
    def optional
	Grammar::Repetition.optional(self)
    end
    alias maybe optional

    # Match between 'min' and 'max' times (inclusive)
    # Match exactly 'min' times if 'max' is either nil or omitted
    def repeat(min, max=nil)
	Grammar::Repetition.repeat(self, min, max)
    end
end
