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

Then(/^zypper (should|should not) contain a service for (base|sdk) product$/) do |condition, product|
  service = {
    'base' => service_name,
    'sdk' => 'SUSE_Linux_Enterprise_Software_Development_Kit_12_x86_64'
  }.fetch(product)

  step 'I run `zypper ls`'
  puts "zypper ls output #{condition} contain \"#{service}\""
  step "the output #{condition} contain \"#{service}\""
  step 'the exit status should be 0'
end

Then(/^zypper (should|should not) contain the repositories for (base|sdk) product$/) do |condition, product|
  version_dot = base_product_version
  version_uscore = version_to_sp_notation(version_dot, '_')
  version_dash = version_to_sp_notation(version_dot, '-')

  if product == 'base'
    prepend_string = (version_dot =~ /15/) ? 'SLE-Product-' : '' # Repos have been renamed in SLES 15
    repositories = [
      "SUSE_Linux_Enterprise_Server_#{version_uscore}_x86_64:#{prepend_string}SLES#{version_dash}-Pool",
      "SUSE_Linux_Enterprise_Server_#{version_uscore}_x86_64:#{prepend_string}SLES#{version_dash}-Updates",
      "SUSE_Linux_Enterprise_Server_#{version_uscore}_x86_64:#{prepend_string}SLES#{version_dash}-Debuginfo-Updates"
    ]
    repositories.pop if version_dot =~ /15/ # SLES 15 does not get the Debuginfo-Updates repo
  elsif product == 'sdk'
    repositories = [
      "SUSE_Linux_Enterprise_Software_Development_Kit_#{version_uscore}_x86_64:SLE-SDK#{version_dash}-Pool",
      "SUSE_Linux_Enterprise_Software_Development_Kit_#{version_uscore}_x86_64:SLE-SDK#{version_dash}-Updates"
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
