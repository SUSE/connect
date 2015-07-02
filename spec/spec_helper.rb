require 'simplecov'

if ENV['TRAVIS']
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end

SimpleCov.minimum_coverage 100
SimpleCov.start do
  add_filter '/spec/'
  add_filter 'vendor' # Don't include vendored stuff
end

require 'rspec'
require 'ap'
require 'byebug'
require 'webmock/rspec'
require 'suse/connect'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f }

RSpec.configure do |c|
  c.order = :random
end

include SUSE::Connect
