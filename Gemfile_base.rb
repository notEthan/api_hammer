source 'https://rubygems.org'

gemspec

gem 'rake'

group(:test) do
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'simplecov'
  gem 'rack-test'
end

group(:doc) do
  gem 'yard'
end

# mutex_m needed by activesupport (remove when updated)
gem 'mutex_m'
