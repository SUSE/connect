Then(/^Set regcode and url options$/) do
  @regcode = ENV['REGCODE'] || YAML.load_file('/root/.regcode')['code']
  @url = ENV['URL'] || 'https://barium.scc.suse.de'
end

### SUSEConnect cmd steps
Then(/^I call SUSEConnect with '(.*)' arguments$/) do |args|
  options = Hash[*args.gsub('--', '').split(' ')]

  step "Set regcode and url options"

  @regcode = 'INVALID_REGCODE' unless options['regcode'] == 'VALID'

  connect = "SUSEConnect --url #{@url}"
  connect << " -r #{@regcode}" if options['regcode']
  connect << " -l #{options['language']}" if options['language']
  connect << " -p #{options['product']}" if options['product']

  puts "Calling '#{connect}' ..."
  step "I run `#{connect}`"
end

Then(/^zypper should contain a service for (base|extension) product$/) do |product|
  if product == 'base'
    service = service_name
  else
    service = 'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64'
  end

  step 'I run `zypper ls`'
  puts "zypper ls output should contain \"#{service}\""
  step "the output should contain \"#{service}\""
  step 'the exit status should be 0'
end

Then(/^zypper should contain a repositories for (base|extension) product$/) do |product|
  if product == 'base'
    repositories = [
      'SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Pool',
      'SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Updates',
      'SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Debuginfo-Updates'
    ]
  else
    repositories = [
      'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64:SLE-SDK12-Pool',
      'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64:SLE-SDK12-Updates'
    ]
  end

  step 'I run `zypper lr`'

  repositories.each do |repo|
    puts "zypper lr output should contain \"#{repo}\""
    step "the output should contain \"#{repo}\""
  end
end

### SUSEConnect library steps
Then(/^SUSEConnect library should respect API headers$/) do
  step 'Set regcode and url options'

  client = SUSE::Connect::Client.new(regcode: @regcode)
  response = SUSE::Connect::Api.new(client).announce_system("Token token=#{@regcode}")

  expect(response.headers['scc-api-version'].first).to eq(SUSE::Connect::Api::VERSION)
end

Then(/^SUSEConnect library should be able to de-register the system$/) do
  client = SUSE::Connect::Client.new(regcode: @regcode)
  client.deregister!
end
