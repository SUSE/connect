Then(/^Set url options$/) do

  @url = ENV['URL'] || SUSE::Connect::Config::DEFAULT_URL
end

Then(/^I call SUSEConnect with '(.*)' arguments$/) do |args|
  options = Hash[*args.gsub('--', '').split(' ')]

  step 'Set url options'

  connect = "SUSEConnect --url #{@url}"
  connect << " -r #{regcode_for_test(options['regcode'])}" if options['regcode']
  connect << " -p #{options['product']}" if options['product']
  connect << " --namespace #{options['namespace']}" if options['namespace']
  connect << ' -s' if options['status']
  connect << '  --write-config' if options['write-config']
  connect << ' --cleanup' if options['cleanup']

  puts "Calling '#{connect}' ..."
  step "I run `#{connect}`"
end

Then(/^zypper (should|should not) contain a service for (base|sdk|wsm) product$/) do |condition, product|
  if product == 'base'
    service = service_name
  elsif product == 'sdk'
    # TODO: unused
    service = 'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64'
  else
    # TODO: unused
    service = 'Web_and_Scripting_Module_12_x86_64'
  end

  step 'I run `zypper ls`'
  puts "zypper ls output #{condition} contain \"#{service}\""
  step "the output #{condition} contain \"#{service}\""
  step 'the exit status should be 0'
end

Then(/^zypper (should|should not) contain the repositories for (base|sdk|wsm) product$/) do |condition, product|
  version_string_uscore, version_string_dash = {
    '12' => [ '12', '12' ],
    '12.1' => [ '12_SP1', '12-SP1' ],
    '12.2' => [ '12_SP2', '12-SP2' ],
    '12.3' => [ '12_SP3', '12-SP3' ]
  }.fetch(base_product_version)

  if product == 'base'
    repositories = [
      "SUSE_Linux_Enterprise_Server_#{version_string_uscore}_x86_64:SLES#{version_string_dash}-Pool",
      "SUSE_Linux_Enterprise_Server_#{version_string_uscore}_x86_64:SLES#{version_string_dash}-Updates",
      "SUSE_Linux_Enterprise_Server_#{version_string_uscore}_x86_64:SLES#{version_string_dash}-Debuginfo-Updates"
    ]
  elsif product == 'sdk'
    repositories = [
      "SUSE_Linux_Enterprise_Software_Development_Kit_#{version_string_uscore}_x86_64:SLE-SDK#{version_string_dash}-Pool",
      "SUSE_Linux_Enterprise_Software_Development_Kit_#{version_string_uscore}_x86_64:SLE-SDK#{version_string_dash}-Updates"
    ]
  else
    repositories = [
      "Web_and_Scripting_Module_#{version_string_uscore}_x86_64:SLE-Module-Web-Scripting#{version_string_dash}-Pool"
    ]
  end

  step 'I run `zypper lr`'

  repositories.each do |repo|
    puts "zypper lr output #{condition} contain \"#{repo}\""
    step "the output #{condition} contain \"#{repo}\""
  end
end

Then(/zypp credentials for (base|sdk|wsm) (should|should not) exist$/) do |product, condition|
  credentials_path = '/etc/zypp/credentials.d/'
  step "a file named \"#{credentials_path}#{service_name}\" #{condition} exist"
end

Then(/zypp credentials for (base|sdk|wsm) (should|should not) contain "(.*)"$/) do |product, condition, content|
  credentials_path = '/etc/zypp/credentials.d/'
  step "the file \"#{credentials_path}#{service_name}\" #{condition} contain \"#{content}\""
end

Then(/^I remove local credentials$/) do
  step 'Prepare SUSEConnect client with a valid regcode'
  @client.instance_eval { SUSE::Connect::System.remove_credentials }
end

Then(/^System cleanup$/) do
  require 'fileutils'

  FileUtils.rm_rf(Dir.glob('/etc/zypp/credentials.d/*'))
  FileUtils.rm_rf(Dir.glob('/etc/zypp/services.d/*'))
  FileUtils.rm_rf(Dir.glob('/etc/zypp/repos.d/*'))
end
