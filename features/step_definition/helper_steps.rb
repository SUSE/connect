def service_name
  product = SUSE::Connect::Zypper.base_product
  if product.identifier == 'openSUSE'
    @service_name ||= "#{product.identifier}_#{product.version}_#{product.arch}"
  else
    identifier = product.instance_variable_get(:@summary).gsub(' ', '_')
    @service_name ||= "#{identifier}_#{product.arch}"
  end
end

And(/^I wait a while$/) do
  sleep 1
end
