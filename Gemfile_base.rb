source 'https://rubygems.org'

# Specify your gem's dependencies in api_hammer.gemspec
gemspec

gem 'byebug'
gem 'wwtd'
if RUBY_VERSION == '2.0.0'
  gem 'nokogiri', '~> 1.6.8'
end
