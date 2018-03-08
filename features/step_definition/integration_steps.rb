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

Then(/^zypper (should|should not) contain a service for (base product|the extension|(.+))$/) do |condition, name|

  case name
  when 'base product'
    service = service_name
  when 'the extension'
    service = OPTIONS['free_extension']['service']
  else
    service = name
  end

  step 'I run `zypper ls`'
  puts "zypper ls output #{condition} contain \"#{service}\""
  step "the output #{condition} contain \"#{service}\""
  step 'the exit status should be 0'
end

Then(/^zypper (should|should not) contain the repositories for (base product|the extension)$/) do |condition, product|
  repositories = if product == 'base product'
                   OPTIONS['base_product']['repositories']
                 elsif product == 'the extension'
                   OPTIONS['free_extension']['repositories']
                 end

  step 'I run `zypper lr`'

  repositories.each do |repo|
    puts "zypper lr output #{condition} contain \"#{repo}\""
    step "the output #{condition} contain \"#{repo}\""
  end
end

Then(/I remove the extension's release packages/) do
  release_packages = OPTIONS['free_extension']['release_packages']
  run("zypper --non-interactive rm #{release_packages}")
  expect(last_command_started).to be_successfully_executed
end

Then(/zypp credentials for base (should|should not) exist$/) do |condition|
  credentials_path = '/etc/zypp/credentials.d/'
  step "a file named \"#{credentials_path}#{service_name}\" #{condition} exist"
end

Then(/zypp credentials for base (should|should not) contain "(.*)"$/) do |condition, content|
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
