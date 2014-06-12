Then(/^Set mandatory client options$/) do
  @regcode = ENV['REGCODE'] || YAML.load_file('/root/.regcode')['code']
  @url = ENV['URL'] || SUSE::Connect::Client::DEFAULT_URL
end

Then(/^SUSEConnect library should respect API headers$/) do
  step 'Set mandatory client options'

  client = SUSE::Connect::Client.new(regcode: @regcode)
  response = SUSE::Connect::Api.new(client).announce_system('Token token=E9DB3A42DF2288')

  expect(response.headers['scc-api-version'].first).to eq(SUSE::Connect::Api::VERSION)
end
