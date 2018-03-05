source 'https://rubygems.org'

group :test, :development do
  gem 'byebug', '~> 8.0.0'
  gem 'yard'
  gem 'awesome_print'
  gem 'pry'
  gem 'scc-codestyle', '0.1.4'
  gem 'ffi', '1.9.18'
end

group :development do
  gem 'redcarpet'
  gem 'ronn'
  gem 'rake'
  # gem 'gem2rpm', '~> 0.10.1' # TODO: let's link this to the repo that contains the --config fix from the suse package
  gem 'bump'
end

group :test do
  gem 'coveralls', require: false
  gem 'rspec', '~> 3.3.0'
  gem 'rspec-its'
  gem 'webmock', '~> 1.21.0'
  gem 'http', '~> 2.2.2'
  gem 'aruba', '~> 0.14.3'
  gem 'cucumber', '3.0.1' # Last cucumber version to support Ruby 2.1
end
