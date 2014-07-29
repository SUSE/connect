default[:connect][:project] = '/tmp/connect'
default[:connect][:osc][:project] = 'SLE_12'
default[:connect][:osc][:arch] = 'x86_64'

default[:connect][:packages] = {
  'gcc' => true,
  'git' => true,
  'osc' => true,
  'build' => true,
  'ruby-devel' => true,
  'rubygem-gem2rpm' => true
}

default[:connect][:gems] = {
  'bundler' => '1.3.5'
}
