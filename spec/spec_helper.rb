require 'simplecov'

if ENV['TRAVIS']
  require 'coveralls'
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
end

SimpleCov.minimum_coverage 100
SimpleCov.start do
  add_filter '/spec/'
end

require 'rspec'
require 'webmock/rspec'
require 'suse/connect'
require 'support/api_webmocks'
require 'support/credentials_mocks'

RSpec.configure do |c|
  c.order = :random
end
