lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
    spec.name          = "grammar"
    spec.version       = '0.2'
    spec.authors       = ["Brandon Fosdick"]
    spec.email         = ["bfoz@bfoz.net"]

    spec.summary       = %q{Parser-independant grammars in Ruby}
    spec.description   = %q{For building a grammar when you don't care about the parser}
    spec.homepage      = 'https://github.com/bfoz/grammar-ruby'
    spec.license       = "BSD"

    spec.files         = `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
    spec.bindir        = "bin"
    spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
    spec.require_paths = ["lib"]

    spec.required_ruby_version   = '>=2.5'      # For the new constant-lookup behavior

    spec.add_development_dependency "bundler", "~> 2"
    spec.add_development_dependency "rake", "~> 10.0"
    spec.add_development_dependency "rspec", "~> 3.0"
end
