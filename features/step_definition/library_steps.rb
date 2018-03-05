When(/^there's a file "(.+)" with a line "(.+)"$/) do |filename, line|
  File.open(filename, 'w') { |f| f.puts(line) }
end

When(/^I should receive the next Service Pack as a migration target$/) do
  next_version = OPTIONS['next_version']
  products = SUSE::Connect::Status.new(@client.config).system_products.map(&:to_openstruct)
  migration_targets = @client.system_migrations(products, kind: :online).flatten.uniq.map(&:shortname)
  expect(migration_targets).to include(next_version)
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
