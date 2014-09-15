Then(/^Set regcode and url options$/) do
  @regcode = ENV['REGCODE'] || YAML.load_file('/root/.regcode')['code']
  @url = ENV['URL'] || SUSE::Connect::Client::DEFAULT_URL
end

### SUSEConnect cmd steps
Then(/^I call SUSEConnect with '(.*)' arguments$/) do |args|
  options = Hash[*args.gsub('--', '').split(' ')]

  step 'Set regcode and url options'

  @regcode = 'INVALID_REGCODE' unless options['regcode'] == 'VALID'

  connect = "SUSEConnect --url #{@url}"
  connect << " -r #{@regcode}" if options['regcode']
  connect << " -p #{options['product']}" if options['product']
  connect << ' -s' if options['status']

  puts "Calling '#{connect}' ..."
  step "I run `#{connect}`"
end

Then(/^zypper should contain a service for (base|sdk|wsm) product$/) do |product|
  if product == 'base'
    service = service_name
  elsif product == 'sdk'
    service = 'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64'
  else
    service = 'Web_and_Scripting_Module_12_x86_64'
  end

  step 'I run `zypper ls`'
  puts "zypper ls output should contain \"#{service}\""
  step "the output should contain \"#{service}\""
  step 'the exit status should be 0'
end

Then(/^zypper should contain a repositories for (base|sdk|wsm) product$/) do |product|
  if product == 'base'
    repositories = [
      'SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Pool',
      'SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Updates',
      'SUSE_Linux_Enterprise_Server_12_x86_64:SLES12-Debuginfo-Updates'
    ]
  elsif product == 'sdk'
    repositories = [
      'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64:SLE-SDK12-Pool',
      'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64:SLE-SDK12-Updates'
    ]
  else
    repositories = [
      'Web_and_Scripting_Module_12_x86_64:SLE-Module-Web-Scripting12-Pool'
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

  client = SUSE::Connect::Client.new(url: @url, regcode: @regcode)
  response = SUSE::Connect::Api.new(client).announce_system("Token token=#{@regcode}")

  expect(response.headers['scc-api-version'].first).to eq(SUSE::Connect::Api::VERSION)
end

Then(/^SUSEConnect library should be able to de-register the system$/) do
  step 'Set regcode and url options'

  client = SUSE::Connect::Client.new(url: @url, regcode: @regcode)
  client.deregister!
end

Then(/^I delete the registered system on SCC only$/) do
  step 'Set regcode and url options'
  client = SUSE::Connect::Client.new(url: @url, regcode: @regcode)
  client.instance_eval { @api.deregister(system_auth) }
end

Then(/^I remove local credentials$/) do
  step 'Set regcode and url options'
  client = SUSE::Connect::Client.new(url: @url, regcode: @regcode)
  client.instance_eval(System.remove_credentials)
end

Then(/^SUSEConnect library should be able to activate a free extension without regcode$/) do
  step 'Set regcode and url options'

  product = SUSE::Connect::Remote::Product.new(identifier: 'sle-module-web-scripting', version: '12', arch: 'x86_64')
  client = SUSE::Connect::Client.new(url: @url, debug: true)
  service = client.activate_product(product)
  SUSE::Connect::System.add_service(service)
end

Then(/^SUSEConnect library should be able to retrieve the product information$/) do
  step 'Set regcode and url options'

  remote_product = SUSE::Connect::Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64')
  client = SUSE::Connect::Client.new(url: @url, regcode: @regcode)
  products = client.show_product(remote_product).extensions.map(&:friendly_name).sort

  products.each {|product| puts "- #{product}" }

  extensions = [
    'SUSE Linux Enterprise High Availability Extension 12 x86_64',
    'SUSE Linux Enterprise Software Development Kit 12 x86_64',
    'Legacy Module 12 x86_64',
    'Advanced Systems Management Module 12 x86_64',
    'SUSE Linux Enterprise Workstation Extension 12 x86_64',
    'Web and Scripting Module 12 x86_64',
    'Public Cloud Module 12 x86_64'
  ].sort

  expect(products).to eq(extensions)
end
