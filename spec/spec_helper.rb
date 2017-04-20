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
require 'byebug'
require 'pry'
require 'awesome_print'
require 'webmock/rspec'
require 'rspec/its'
require 'suse/connect'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f }

RSpec.configure do |c|
  c.order = :random
end

include SUSE::Connect
