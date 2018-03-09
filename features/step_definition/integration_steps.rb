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

Then(/^zypper (should|should not) contain a service for (base product|the extension)$/) do |condition, product|
  service = {
    'base product' => service_name,
    'the extension' => OPTIONS['free_extension']['service']
  }.fetch(product)

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

When(/^System has free extension$/) do
  step "I run `zypper se -x #{OPTIONS['free_extension']['release_package']}`"
  step 'the exit status should be 0'
end

Then(/^It deregisters free extension$/) do
  identifier = OPTIONS['free_extension']['identifier'].split('/').first
  step "the output should contain \"#{identifier}\""
  step "I run `zypper se -x #{OPTIONS['free_extension']['release_package']}`"
  step 'the exit status should be 104'
end

Then(/^System cleanup$/) do
  require 'fileutils'

  FileUtils.rm_rf(Dir.glob('/etc/zypp/credentials.d/*'))
  FileUtils.rm_rf(Dir.glob('/etc/zypp/services.d/*'))
  FileUtils.rm_rf(Dir.glob('/etc/zypp/repos.d/*'))
end
