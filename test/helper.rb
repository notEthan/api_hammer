proc { |p| $:.unshift(p) unless $:.any? { |lp| File.expand_path(lp) == p } }.call(File.expand_path('../lib', File.dirname(__FILE__)))

require 'bundler'
Bundler.setup

require 'simplecov'
SimpleCov.start

# NO EXPECTATIONS 
ENV["MT_NO_EXPECTATIONS"] = ''

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'api_hammer'
