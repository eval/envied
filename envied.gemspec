# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'envied'

Gem::Specification.new do |spec|
  spec.name          = "envied"
  spec.version       = ENVied::VERSION
  spec.authors       = ["Gert Goet"]
  spec.email         = ["gert@thinkcreate.nl"]
  spec.summary       = %q{ENV on EPO}
  spec.description   = %q{ENV on EPO. Or: ensure presence and type of your app's ENV-variables.}
  spec.homepage      = "https://github.com/eval/envied"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "virtus", '~> 1.0.1'
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", '3.0.0.beta2'
end
