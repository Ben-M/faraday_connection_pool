# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faraday_connection_pool/version'

Gem::Specification.new do |spec|
  spec.name          = "faraday_connection_pool"
  spec.version       = FaradayConnectionPool::VERSION
  spec.authors       = ["Ben Maraney"]
  spec.email         = ["ben@maraney.com"]
  spec.summary       = "A persistent Net::Http adapter for Faraday with a connection pool shared across threads and fibres."
  spec.homepage      = "https://github.com/Ben-M/faraday_connection_pool"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_dependency "faraday", "~> 0.9"
  spec.add_dependency "connection_pool", "~> 2.1"
end
