When(/^I have a system with activated base product$/) do
  step "I call SUSEConnect with '--regcode VALID' arguments"
  step 'the exit status should be 0'
end

When(/I activate a paid extension/) do
  step "I call SUSEConnect with '--product #{OPTIONS['paid_extension']['identifier']}' arguments"
end

When(/I activate a free extension/) do
  step "I call SUSEConnect with '--product #{OPTIONS['free_extension']['identifier']}' arguments"
end

Then(/a credentials file is created for the extension/) do
  file = OPTIONS['free_extension']['credentials_file']
  expect(file).to be_an_existing_file
  expect(file).to have_file_content(a_string_starting_with 'username=SCC_')
end
