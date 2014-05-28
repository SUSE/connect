name 'connect_test_node'
description 'Prepares VM instance for SUSEConnect testing'

run_list(
  'recipe[ohai]',
  'recipe[connect::repositories]',
  'recipe[connect::packages]',
  'recipe[connect::rubygems]',
  'recipe[connect::suse_connect]',
  'recipe[connect::integration_tests]',
  'recipe[connect::clean_up]'
)
