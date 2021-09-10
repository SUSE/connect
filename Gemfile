source 'https://rubygems.org'

group :test, :development do
  gem 'byebug', '~> 8.0.0'
  gem 'yard'
  gem 'awesome_print'
  gem 'pry'
  gem 'scc-codestyle', '0.2.1' # lock to 0.2.1, because rubocop 0.53 needs ruby >=2.2, SLE12 has ruby 2.1
  gem 'ffi', '1.9.18'
end

group :development do
  gem 'redcarpet'
  gem 'ronn'
  gem 'rake'
  gem 'bump', '~> 0.6.1', '< 0.7' # later versions of bump require ruby 2.2 which is not on SLE12
end

group :test do
  gem 'coveralls', require: false
  gem 'rspec', '~> 3.3.0'
  gem 'rspec-its'
  gem 'webmock', '~> 1.21.0'
  gem 'http', '~> 2.2.2'
  gem 'aruba', '~> 0.14.4'
  gem 'cucumber', '3.0.1' # Last cucumber version to support Ruby 2.1
end

gem 'contracts', '> 0.16', '< 0.17'
