source 'https://rubygems.org'

group :test, :development do
  gem 'byebug'
  gem 'yard'
  gem 'awesome_print'
  gem 'pry'
end

group :development do
  gem 'redcarpet'
  gem 'ronn'
  gem 'rake'
  #gem 'gem2rpm', '~> 0.10.1' # TODO: let's link this to the repo that contains the --config fix from the suse package
  gem 'bump'
end

group :test do
  gem 'rubocop', '~> 0.20.1', :require => false
  gem 'coveralls', :require => false
  gem 'rspec', '~> 3.3.0'
  gem 'rspec-its'
  gem 'webmock', '~> 1.21.0'
  gem 'http', '~> 0.8.12'
  gem 'aruba', '~> 0.7.4'
end
