source 'https://rubygems.org'

gemspec

gem 'wwtd'

gem 'rack', '~> 1.0'
gem 'actionpack', '~> 4.0'

if RUBY_VERSION == '2.0.0'
  gem 'nokogiri', '~> 1.6.8'
  gem 'public_suffix', '~> 2.0'
end
