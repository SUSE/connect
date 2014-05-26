require 'suse/connect/version'

def service_name
  base_product = SUSE::Connect::Zypper.base_product
  if base_product[:name] == 'openSUSE'
    @service_name ||= "#{base_product[:name]}_#{base_product[:version]}_#{base_product[:arch]}"
  else
    @service_name ||= "#{base_product[:summary].gsub(' ', '_')}_#{base_product[:arch]}"
  end
end

And(/^I wait a while$/) do
  sleep 1
end
