def service_name
  base_product = SUSE::Connect::Zypper.base_product
  @service_name ||= "#{base_product[:name]}_#{base_product[:version]}_#{base_product[:arch]}"
end

And(/^I wait a while$/) do
  sleep 2
end