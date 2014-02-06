Given(/^I use suseconnect client with valid token$/) do
  step 'I run `SUSEConnect --token 34fd2b04-4e40-425c-a137-7721e0303382`'
end

Then(/^output should inform us about requirement to run as root$/) do
  assert_exact_output('Insufficient permissions, please run SUSEConnect as root',  all_output.chomp)
end

Then(/^output should inform us about you need an argument if running with host parameter$/) do
  assert_exact_output('Please provide host parameter', all_output.chomp)
end

Then(/^outputs should not contain info about required host param$/) do
  assert_no_partial_output('Please provide host parameter', all_output.chomp)
end

Then(/^output should inform us about you need an argument if running with port parameter$/) do
  assert_exact_output('Please provide port parameter', all_output.chomp)
end

Then(/^outputs should not contain info about required port param$/) do
  assert_no_partial_output('Please provide port parameter', all_output.chomp)
end
