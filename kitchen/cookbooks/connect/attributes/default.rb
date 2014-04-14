default[:connect][:project] = '/tmp/connect'

default[:connect][:packages] = {
  'gcc' => true,
  'git' => true,
  'osc' => true,
  'build' => true,
  'ruby-devel' => true
}

default[:connect][:gems] = {
  'bundler' => '1.3.5',
  'gem2rpm' => '0.9.2'
}
