source 'https://rubygems.org'

group :test, :development do
  gem 'byebug'
  gem 'yard'
  gem 'awesome_print'
end

group :development do
  gem 'redcarpet'
  gem 'ronn'
  gem 'rake'
  gem 'gem2rpm', '~> 0.10.1'
  gem 'gem-release'
end

group :test do
  gem 'rubocop', '~> 0.20.1', :require => false
  gem 'coveralls', :require => false
  gem 'rspec', '~> 2.14'
  gem 'webmock', '~> 1.15'
  gem 'http', '>= 0.6.0'
  gem 'aruba'
end

gemspec
