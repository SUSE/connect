Then(/^the output should contain exactly current version number$/) do
  assert_exact_output(SUSE::Connect::VERSION, all_output.chomp)
end
