module Grammar
    class Base
	class << self
	    # Case equality
	    # @param other [Any]
	    # @return [Bool]
	    def ===(other)
		(other.is_a?(Class) and (other <= self)) or other.is_a?(self)
	    end

	    def |(other)
		Alternation.with(self, other)
	    end

	    def +(other)
		Concatenation.with(self, other)
	    end

	    # @return [Regexp]
	    def to_regexp
		Regexp.new(self.to_re)
	    end
	end
    end
end
