When(/^I have a system with activated base product$/) do
  step "I call SUSEConnect with '--regcode VALID' arguments"
  step 'the exit status should be 0'
end
