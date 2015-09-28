When(/^I should receive '(.*)' as a migration target$/) do |target_name|
  products = SUSE::Connect::Status.new(@client.config).system_products.map(&:to_openstruct)
  migrations =  @client.system_migrations(products)
  assert_exact_output(target_name, migrations.first.first.shortname)
end

When(/^I call the migration rollback method$/) do
  SUSE::Connect::Migration.rollback
end
