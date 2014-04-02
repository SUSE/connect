name 'connect_test_node'
description 'Prepares VM instance for SUSEConnect testing'

run_list(
  'recipe[connect::packages]',
  'recipe[connect::rubygems]',
  'recipe[connect::suse_connect]'
)

