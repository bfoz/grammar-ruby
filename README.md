# Grammar

This is an attempt to make a cross-parser grammar specification for parsers written in Ruby. The result is a very opiniated gem that is cranky about the sad state of grammar languages. _Grammar_ doesn't have a grammar file format, or even care what grammar file you use, so long as it can be translated into Grammar objects. The Grammar object hierarchy attempts to support all of the features supported by all of the major parsers. If you create a grammar using features that aren't supported by your favorite parser, then it's up to that parser to complain about the grammar you tried to feed it.

_Grammar_ doesn't attempt to mitigate left-recursive alternations; a parser is expected to either handle the grammar properly, or to report an appropriate error for any grammar element that it can't handle.

## Grammars are Modules

Grammars are Ruby Modules, and the grammar rules are constants defined in the grammar module.

```ruby
grammar :MyGrammar do
    MyRule = ...
end
```

or, equivalently...

```ruby
module MyGrammar
    using Grammar::DSL
    MyRule = ...
end
```

## Matches are instances

In the land of Grammar, grammar elements (sometimes called 'parslets') are subclasses of the primary Grammar classes (ie. _Alternation_, _Concatenation_, etc). Matches resulting from parsing input that matches the grammar are instances of the subclasses. For example:

```ruby
foo_bar = Grammar::Alternation.with('foo', 'bar')	# => Class:0xXXXXX
...
parser.parse('foo')					# => #<Grammar::Alternation @match='foo'>
```

## Recursion

Most uses of recursion in typical parser grammars are actually a hack for implementing repetition. In _Grammar_, repetition is represented explicitly using the _Repetition_ class, which eliminates most of the common use cases. However, that still leaves a few cases to be handled. The _Parenthesis Language_ being a notable example.

When using the DSL to specify a grammar module, the relevant methods will attempt to detect common uses of recursion and handle them appropriately.

### Alternation

All recursive alternations are effecively left-recursive from the perspective of a top-down parser, and may be considered left-recursive by bottom-up parsers (depending on the specific implementation). And we all know how that turns out. Fortunately, _Grammar_ knows that you really wanted a repetition with at least one repeat, and will give you what you wanted instead of what you asked for.

```ruby
Rule0 = Grammar::Alternation.with('abc', 'def', Rule0)	# => NameError('You are a bad person')
```

If you use the DSL form, you'll get something more reasonable (ie. a repeating alternation).

```ruby
grammar :MyGrammar do
    alternation :Rule0 { elements 'abc', 'def', Rule0}	#=> Grammar::Repetition.at_least(1, Grammar::Alternation.with('abc', 'def'))
end
```

But, you could go easy on yourself and just do it the right way...

```ruby
Rule0 = Grammar::Alternation.with('abc', 'def').at_least(1)
```

See how easy that is?

### Left Recursion

If your grammar does this, you either meant to use repetition, or you should be ashamed of yourself.

```ruby
Rule0 = Grammar::Concatenation.with(Rule0, ')')		# => NameError('Again?')
```

If you use the DSL it will try to save you from yourself:

```ruby
grammar :MyGrammar do
    concatenation :Rule0 { elements Rule0, ')' }	# => Rule0 = Grammar::Repetition.any(')')
end
```

But you should really just use repetition the way it was meant to be used instead of trying to fake it with recursion.

```ruby
Rule0 = Grammar::Repetition.any(')')
```

### Right Recursion

Again, if you're doing this you should be using repetition.

```ruby
Rule0 = Grammar::Concatenation.with('(', Rule0)		# => NameError('Seriously?')
```

And once again, the _Grammar_ DSL will clean up your mess:

```ruby
grammar :MyGrammar do
    concatenation :Rule0 { elements '(', Rule0 }	# => Rule0 = Grammar::Repetition.one_or_more('(')
end
```

But seriously. Just stop.

### Center Recursion

The only element in _Grammar_ that can support center recursion is _Concatenation_, and the only way to do it is with the DSL (but you already knew that).

```ruby
grammar :MyGrammar do
    concatenation :Rule0 do
    	elements '(', Rule0, ')'
    end
end
```

The _Grammar_ DSL will handle this by creating a _Recursion_ proxy object instead of the _Concatenation_ that you thought you wanted. It's then up to any parser employing the grammar to map the _Recursion_ proxy to whatever mechanism said parser uses for handling center-recursion. If the parser can't handle center-recursion, then it's expected to report an appropriate error.

There's also the case of the "odd number of x's"

```ruby
Rule0 = Grammar::Alternation.with(Grammar::Concatenation.with('x', Rule0, 'x'), 'x')
```

which is normally meant to repesent a repetition that's constrained to an odd number of repeats greater than 2. This can be represented in _Grammar_ with

```ruby
Rule0 = Repetition.with('x', minimum:3, &:odd?)
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grammar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grammar

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bfoz/grammar.
