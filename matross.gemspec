# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "matross/version"

Gem::Specification.new do |spec|
  spec.name          = "matross"
  spec.version       = Matross::VERSION
  spec.authors       = ["Artur Rodrigues", "Joao Sa"]
  spec.email         = ["arturhoo@gmail.com", "me@joaomsa.com"]
  spec.description   = %q{Our collection of opnionated Capistrano recipes}
  spec.summary       = %q{Our collection of opnionated Capistrano recipes}
  spec.homepage      = "https://github.com/innvent/matross"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry"

  spec.add_dependency "capistrano", "2.15.4"
end


