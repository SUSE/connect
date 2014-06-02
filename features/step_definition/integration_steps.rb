Then /^I call SUSEConnect with '(.*)' arguments$/ do |args|
  options = Hash[*args.gsub('--', '').split(' ')]
  if options['regcode'] == 'VALID'
    @regcode = ENV['REGCODE'] || YAML.load_file('/root/.regcode')['code']
  else
    @regcode = 'INVALID_REGCODE'
  end

  @url = ENV['URL'] || SUSE::Connect::Client::DEFAULT_URL

  connect = "SUSEConnect --url #{@url}"
  connect << " -r #{@regcode}" if options['regcode']
  connect << " -l #{options['language']}" if options['language']
  connect << " -p #{options['product']}" if options['product']

  puts "Calling '#{connect}' ..."
  step "I run `#{connect}`"
end

Then(/^SUSEConnect should create the '(.+)' file$/) do |name|
  file_name = (name == 'service credentials') ? service_name : name
  file = "/etc/zypp/credentials.d/#{file_name}"

  step "a file named \"#{file}\" should exist"
end

And(/^'(.*)' file should contain '(.+)' prefixed system guid$/) do |name, prefix|
  file_name = (name == 'Service credentials') ? service_name : name
  file = "/etc/zypp/credentials.d/#{file_name}"

  step "the file \"#{file}\" should contain \"#{prefix}\""
end

Then(/^SUSEConnect should add a new zypper service for base product$/) do
  step 'I run `zypper ls`'
  step "the output should contain \"#{service_name}\""
  step 'the exit status should be 0'
end

Then(/^SUSEConnect should add a new repositories for base product$/) do
  step 'I run `zypper lr`'
  step "the output should contain \"#{service_name}\""
  step 'the exit status should be 0'
end
