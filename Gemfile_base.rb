source 'https://rubygems.org'

gemspec

gem 'rake'
gem 'byebug'
gem 'wwtd'
if RUBY_VERSION == '2.0.0'
  gem 'nokogiri', '~> 1.6.8'
end

group(:test) do
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'simplecov'
  gem 'rack-test'
end

group(:doc) do
  gem 'yard'
end
