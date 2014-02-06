require 'coveralls'
Coveralls.wear!

require 'rspec'
require 'webmock/rspec'
require 'suse/connect'
require 'support/api_webmocks'
require 'support/credentials_mocks'

RSpec.configure do |c|
  c.order = :random
end
