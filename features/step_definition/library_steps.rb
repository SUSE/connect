When(/^I should receive '(.*)' as a migration target$/) do |target_name|
  products = SUSE::Connect::Status.new(@client.config).system_products.map(&:to_openstruct)
  migrations =  @client.system_migrations(products).to_s
  assert_partial_output(target_name, migrations)
end

When(/^I call the migration rollback method$/) do
  SUSE::Connect::Migration.rollback
end

Then(/^Prepare SUSEConnect client with a valid regcode/) do
  step 'Set url options'
  @client = SUSE::Connect::Client.new(SUSE::Connect::Config.new.merge!(url: @url, regcode: regcode_for_test('VALID')))
end

Then(/^I deregister the system$/) do
  step 'Prepare SUSEConnect client with a valid regcode'
  @client.deregister!
end

Then(/^I delete the system on SCC$/) do
  step 'Prepare SUSEConnect client with a valid regcode'
  @client.instance_eval { @api.deregister(system_auth) }
end
