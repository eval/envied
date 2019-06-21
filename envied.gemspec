# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "envied/version"

Gem::Specification.new do |spec|
  spec.name          = "envied"
  spec.version       = ENVied::VERSION
  spec.authors       = ["Gert Goet", "Javier Julio"]
  spec.email         = ["gert@thinkcreate.nl", "jjfutbol@gmail.com"]
  spec.summary       = %q{Ensure presence and type of ENV-variables}
  spec.description   = %q{Ensure presence and type of your app's ENV-variables.}
  spec.homepage      = "https://github.com/eval/envied"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/eval/envied.git"
  spec.metadata["changelog_uri"] = "https://github.com/eval/envied/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "thor", "~> 0.15"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
