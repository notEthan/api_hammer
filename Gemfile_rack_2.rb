source 'https://rubygems.org'

gemspec

gem 'wwtd'

gem 'rack', '~> 2.0'
gem 'actionpack', '~> 5.0'

if RUBY_VERSION == '2.0.0'
  gem 'nokogiri', '~> 1.6.8'
end
