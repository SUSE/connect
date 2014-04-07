Given(/^I register a system with regcode '(.+)'$/) do |regcode|
  step "I run `SUSEConnect --token #{regcode}`"
  step 'the exit status should be 0'
end

Given(/^I register a system with (valid|invalid) regcode$/) do |condition|
  if condition == 'valid'
    puts ENV['REGCODE'].inspect
    step "I run `SUSEConnect --token #{ENV['REGCODE']}`"
  else
    step "I run `SUSEConnect --token INVALID_REGCODE`"
  end

  step 'the exit status should be 0'
end

Then(/^SUSEConnect should create the '(.+)' file$/) do |file|
  step 'a file named "/etc/zypp/credentials.d/SCCcredentials" should exist'
end

And(/^Credentials file should contain 'SCC' prefixed system guid$/) do
  step 'I run `cat /etc/zypp/credentials.d/SCCcredentials`'
  step 'the stdout should contain "username=SCC_"'
end
