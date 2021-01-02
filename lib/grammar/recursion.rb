require 'delegate'

require_relative 'repeatable'

class Grammar::Recursion < SimpleDelegator
    include Grammar::Repeatable

    attr_accessor :grammar

    def initialize(grammar=nil)
	super
	@grammar = grammar
    end

    def ==(other)
	# The superclass method checks for object_id equality, which allows for short-circuit logic when +other+ is the same object as +self+
	super or (self.grammar == other.grammar)
    rescue NoMethodError
    	nil
    end

    # Hash equality
    def eql?(other)
	super or self.grammar.eql?(other.grammar)
    rescue NoMethodError
	nil
    end

    def hash
	self.grammar.hash + super
    end

    # @group Predicates

    # @return [Bool]	Returns true if the first element is left recursive
    def left_recursive?(root = nil, *path)
	if root.nil?
	    root = self
	else
	    return true if self.equal?(root) or self.grammar&.equal?(root) or (self.grammar&.is_a?(String) and (self.grammar == root))
	    return false if path.include?(self)
	    path.push self
	end

	self.grammar&.respond_to?(:left_recursive?) and self.grammar&.left_recursive?(root, *path)
    end

    # All {Recursions} are assumed to be optional unless otherwise noted. This helps avoid infinite recursions.
    # @return [True]
    def optional?
	true
    end

    # @param [Grammar]  The potential recursion root to check for. Defaults to self.
    # @return [Bool]	Returns true if grammar is recursive
    def recursive?(root = nil, *path)
        if root.nil?
            root = self
        else
            return true if self.equal?(root) or self.grammar&.equal?(root) or (self.grammar&.is_a?(String) and (self.grammar == root))
            return false if path.include?(self)
            path.push self
        end

	self.grammar&.respond_to?(:recursive?) and self.grammar&.recursive?(root, *path)
    end

    # @endgroup

    # @group Repeatable

    # {Recursion}s are always optional (to avoid infinite recursion), so nothing to do here
    def optional
	self
    end

    # @endgroup Repeatable

    def inspect
	"<Recursion:" + self.grammar.inspect + ">"
    end

    class << self
	def with(grammar)
	    self.new(grammar)
	end
    end
end
