Given(/^I register a system with (valid|invalid) regcode$/) do |condition|
  if condition == 'valid'
    step "I run `SUSEConnect -r #{ENV['REGCODE']} #{"--url http://localhost:3000" if ENV['LOCAL_SERVER']}`"
  else
    step 'I run `SUSEConnect -r INVALID_REGCODE`'
  end

  step 'the exit status should be 0'
end

Then(/^SUSEConnect should create the '(.+)' file$/) do |file_name|
  file_name = file_name.include?('SCCcredentials') ? file_name : service_name
  file = "/etc/zypp/credentials.d/#{file_name}"

  step "a file named \"#{file}\" should exist"
end

And(/^(Service credentials|SCCcredentials) file should contain '(.+)' prefixed system guid$/) do |file_name, prefix|
  file_name = file_name.include?('SCCcredentials') ? file_name : service_name
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
