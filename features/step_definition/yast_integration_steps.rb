When(/^I call YaST registration "([^"]*)" method(.*)$/) do |method, options|
  # initialize the @reg_code and @url settings
  step 'Set regcode and url options'

  yast_registration = Registration::Registration.new(@url)

  # pretend YaST is running in the text mode
  allow(Yast::UI).to receive(:GetDisplayInfo).and_return('TextMode' => true)

  case method
  # registering the system
  when 'register'
    base_product = Registration::SwMgmt.find_base_product
    target_distro = base_product['register_target']
    @yast_return = yast_registration.register('email', @regcode, target_distro)
  when 'register_product'
    case options
    # registering the base product
    when ''
      base_product_data = Registration::SwMgmt.base_product_to_register
      base_product_data['reg_code'] = @regcode
      allow(Yast::Mode).to receive(:commandline).and_return(true)
      @yast_return = yast_registration.register_product(base_product_data, 'email')
    # registering the SDK extension
    when " with \"sdk\" product"
      sdk = {
        'name'     => 'sle-sdk',
        'arch'     => 'x86_64',
        'version'  => '12'
      }
      @yast_return = yast_registration.register_product(sdk)
    end
  when 'get_addon_list'
    @yast_return = yast_registration.get_addon_list
  when 'migration_products'
    installed_products = ::Registration::SwMgmt.installed_products.map do |product|
      ::Registration::SwMgmt.remote_product(product)
    end

    @yast_return = yast_registration.migration_products(installed_products)
  else
    raise "Unknown method: #{method}"
  end
end

Then(/^the returned list should contain the "([^"]*)" extension$/) do |name|
  sdk = @yast_return.find {|ext| ext.identifier == name }
  expect(sdk).to_not be_nil
end

Then(/^the result should contain the SP(\d+) migration target$/) do |version|
  migration_target = @yast_return.find do |migration|
    migration.any? {|product| product.version = "12.#{version}" }
  end

  expect(migration_target).to_not be_nil
end
