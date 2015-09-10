Given(/^I use suseconnect client with valid token$/) do
  step 'I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382`'
end

Then(/^output should inform us about requirement to run as root$/) do
  assert_exact_output('Insufficient permissions, please run SUSEConnect as root',  all_output.chomp)
end

Then(/^output should inform us about you need an argument if running with url parameter$/) do
  assert_exact_output('Please provide registration server URL', all_output.chomp)
end

Then(/^outputs should not contain info about required url param$/) do
  assert_no_partial_output('Please provide url parameter', all_output.chomp)
end

Then(/^output should inform us about you need an argument if running with port parameter$/) do
  assert_exact_output('Please provide port parameter', all_output.chomp)
end

Then(/^outputs should not contain info about required port param$/) do
  assert_no_partial_output('Please provide port parameter', all_output.chomp)
end

Then(/^the output should inform us that the regcode was invalid$/) do
  assert_expired_output('Invalid registration code.', all_output.chomp)
end

Then(/^the output should inform us that the regcode needs to be activated$/) do
  assert_exact_output('Not yet activated registration code. Please visit https://scc.suse.com to activate it.', all_output.chomp)
end

Then(/^the output should inform us that the regcode has expired$/) do
  assert_partial_output('Expired registration code.', all_output.chomp)
end
