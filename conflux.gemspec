# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conflux/version'

Gem::Specification.new do |spec|
  spec.name          = "conflux"
  spec.version       = Conflux::VERSION
  spec.authors       = ["Ben Whittle"]
  spec.email         = ["benwhittle31@gmail.com"]
  spec.summary       = "gem to test an ajax request"
  spec.homepage      = "https://www.github.com/GoConflux/conflux-cli"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["conflux"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client",     "1.6.8"

  spec.add_development_dependency "rails", "~> 4.2"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-doc"
end
