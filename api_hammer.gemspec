# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.any? { |lp| File.expand_path(lp) == File.expand_path(lib) }
require 'api_hammer/version'

Gem::Specification.new do |spec|
  spec.name          = 'api_hammer'
  spec.version       = ApiHammer::VERSION
  spec.authors       = ['Ethan']
  spec.email         = ['ethan@unth']
  spec.summary       = 'an API tool'
  spec.description   = 'actually a set of small API-related tools. very much unlike a hammer at all, which ' +
    'is one large tool.'
  spec.homepage      = 'https://github.com/notEthan/api_hammer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0") - ['.gitignore']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = `git ls-files -z test`.split("\x0") + [
    '.simplecov',
  ]
  spec.require_paths = ['lib']

  spec.add_dependency 'rack'
  spec.add_dependency 'faraday'
  spec.add_dependency 'term-ansicolor'
  spec.add_dependency 'json'
  spec.add_dependency 'addressable'
  spec.add_dependency 'coderay'
  spec.add_dependency 'i18n'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'sqlite3'
end
