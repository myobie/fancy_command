# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fancy_command/version'

Gem::Specification.new do |spec|
  spec.name          = "fancy_command"
  spec.version       = FancyCommand::VERSION
  spec.authors       = ["myobie"]
  spec.email         = ["me@nathanherald.com"]
  spec.summary       = %q{Real-time streaming command output and other nice things}
  spec.description   = %q{I get really tired of not having a good Command class in ruby, so here it is.}
  spec.homepage      = "http://github.com/myobie/fancy_command"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
