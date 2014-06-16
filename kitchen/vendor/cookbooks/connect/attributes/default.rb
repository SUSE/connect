default[:connect][:project] = '/tmp/connect'
default[:connect][:osc][:project] = 'SLE_12'
default[:connect][:osc][:arch] = 'x86_64'

default[:connect][:packages] = {
  'gcc' => true,
  'git' => true,
  'osc' => true,
  'build' => true,
  'ca-certificates-suse' => true,
  'ruby-devel' => true
}

default[:connect][:gems] = {
  'bundler' => '1.3.5',
  'gem2rpm' => '0.9.2'
}
