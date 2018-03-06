Then(/^the output should contain exactly current version number$/) do
  expect(last_command_started).to have_output SUSE::Connect::VERSION
end
