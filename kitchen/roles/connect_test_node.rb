name 'connect_test_node'
description 'Prepares VM instance for SUSEConnect testing'

run_list(
  'recipe[ohai]',
  'recipe[connect::packages]',
  'recipe[connect::rubygems]',
  'recipe[connect::SUSEConnect]'
)

