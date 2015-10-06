Then(/^Set regcode and url options$/) do
  test_regcodes = YAML.load_file('/root/.regcode')
  @valid_regcode =  ENV['REGCODE'] || test_regcodes['code']
  @expired_regcode = test_regcodes['expired_code'] || "regcode file does not contain 'expired_code'!!"
  @notyetactivated_regcode = test_regcodes['notyetactivated_code'] || "regcode file does not contain 'notyetactivated_code'!!"
  @url = ENV['URL'] || SUSE::Connect::Config::DEFAULT_URL
end

Then(/^I call SUSEConnect with '(.*)' arguments$/) do |args|
  options = Hash[*args.gsub('--', '').split(' ')]

  step 'Set regcode and url options'

  regcode = case options['regcode']
            when nil
            when 'INVALID'
              'INVALID_REGCODE'
            when 'EXPIRED'
              @expired_regcode
            when 'NOTYETACTIVATED'
              @notyetactivated_regcode
            when 'VALID'
              @valid_regcode
            else
              @options['regcode']
  end

  connect = "SUSEConnect --url #{@url}"
  connect << " -r #{regcode}" if options['regcode']
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

Then(/^zypper should contain the repositories for (base|sdk|wsm) product$/) do |product|
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
