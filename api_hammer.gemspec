# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.any? { |lp| File.expand_path(lp) == File.expand_path(lib) }
require 'api_hammer/version'

Gem::Specification.new do |spec|
  spec.name          = 'api_hammer'
  spec.version       = ApiHammer::VERSION
  spec.authors       = ['Ethan']
  spec.email         = ['ethan@unth']
  spec.summary       = ''
  spec.description   = ''
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z lib`.split("\x0") + [
    'LICENSE.txt',
    'README.md',
    'Rakefile.rb',
  ]
  spec.executables   = []
  spec.test_files    = `git ls-files -z test`.split("\x0") + [
    '.simplecov',
  ]
  spec.require_paths = ['lib']

  spec.add_dependency 'rack'
  spec.add_dependency 'term-ansicolor'
  spec.add_dependency 'json'
  spec.add_dependency 'addressable'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'simplecov'
end
