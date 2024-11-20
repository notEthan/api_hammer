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
  spec.files         = [
    *%w(
      .yardopts
      CHANGELOG.md
      LICENSE.txt
      README.md
      api_hammer.gemspec
      bin/hc
    ),
    *Dir['lib/**/*'],
  ].reject { |f| File.lstat(f).ftype == 'directory' }
  spec.bindir        = 'bin'
  spec.executables   = ['hc']
  spec.require_paths = ['lib']

  spec.add_dependency 'rack'
  spec.add_dependency 'faraday', '~> 1.0'
  spec.add_dependency 'term-ansicolor'
  spec.add_dependency 'json'
  spec.add_dependency 'json_pure'
  spec.add_dependency 'addressable'
  spec.add_dependency 'coderay'
  spec.add_dependency 'i18n'
end
