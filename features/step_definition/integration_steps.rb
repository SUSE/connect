Then(/^Set regcode and url options$/) do
  @valid_regcode =  ENV['REGCODE'] || YAML.load_file('/root/.regcode')['code']
  @expired_regcode = YAML.load_file('/root/.regcode')['expired_code']
  @notyetactivated_regcode = YAML.load_file('/root/.regcode')['g']
  @url = ENV['URL'] || SUSE::Connect::Config::DEFAULT_URL
end

Then(/^Prepare SUSEConnect client with a valid regcode/) do
  step 'Set regcode and url options'
  @client = SUSE::Connect::Client.new(SUSE::Connect::Config.new.merge!(url: @url, regcode: @regcode))
end

Then(/^I call SUSEConnect with '(.*)' arguments$/) do |args|
  options = Hash[*args.gsub('--', '').split(' ')]

  step 'Set regcode and url options'

  case options['regcode']
  when 'INVALID'
    @regcode = 'INVALID_REGCODE'
  when 'EXPIRED'
    @regcode = @expired_regcode
  when 'NOTYETACTIVATED'
    @regcode = @notyetactivated_regcode
  when 'VALID'
    @regcode = @valid_regcode
  end

  connect = "SUSEConnect --url #{@url}"
  connect << " -r #{@regcode}" if options['regcode']
  connect << " -p #{options['product']}" if options['product']
  connect << ' -s' if options['status']
  connect << ' --cleanup' if options['cleanup']

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
  step 'Prepare SUSEConnect client with a valid regcode'

  response = SUSE::Connect::Api.new(@client).announce_system("Token token=#{@regcode}")
  expect(response.headers['scc-api-version'].first).to eq(SUSE::Connect::Api::VERSION)
end

Then(/^I deregister the system$/) do
  step 'Prepare SUSEConnect client with a valid regcode'
  @client.deregister!
end

Then(/^I delete the system on SCC$/) do
  step 'Prepare SUSEConnect client with a valid regcode'
  @client.instance_eval { @api.deregister(system_auth) }
end

Then(/^I remove local credentials$/) do
  step 'Prepare SUSEConnect client with a valid regcode'
  @client.instance_eval { SUSE::Connect::System.remove_credentials }
end

Then(/^SUSEConnect library should be able to activate a free extension without regcode$/) do
  step 'Set regcode and url options'

  product = SUSE::Connect::Remote::Product.new(identifier: 'sle-module-web-scripting', version: '12', arch: 'x86_64')
  client = SUSE::Connect::Client.new(SUSE::Connect::Config.new.merge!(url: @url))
  service = client.activate_product(product)
  SUSE::Connect::System.add_service(service)
end

Then(/^SUSEConnect library should be able to retrieve the product information$/) do
  step 'Prepare SUSEConnect client with a valid regcode'

  remote_product = SUSE::Connect::Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64')
  products = @client.show_product(remote_product).extensions.map(&:friendly_name).sort

  products.each {|product| puts "- #{product}" }

  extensions = [
    'Advanced Systems Management Module 12 x86_64',
    'Containers Module 12 x86_64',
    'Legacy Module 12 x86_64',
    'Public Cloud Module 12 x86_64',
    'SUSE Cloud for SLE 12 Compute Nodes 5 x86_64',
    'SUSE Enterprise Storage 1 x86_64',
    'SUSE Linux Enterprise High Availability Extension 12 x86_64',
    'SUSE Linux Enterprise Live Patching 12 x86_64',
    'SUSE Linux Enterprise Software Development Kit 12 x86_64',
    'SUSE Linux Enterprise Workstation Extension 12 x86_64',
    'Web and Scripting Module 12 x86_64'
  ]

  expect(products).to match_array(extensions)
end

Then(/^System cleanup$/) do
  require 'fileutils'

  FileUtils.rm_rf(Dir.glob('/etc/zypp/credentials.d/*'))
  FileUtils.rm_rf(Dir.glob('/etc/zypp/services.d/*'))
  FileUtils.rm_rf(Dir.glob('/etc/zypp/repos.d/*'))
end
