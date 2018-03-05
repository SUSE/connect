$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

require 'suse/connect'
require 'aruba/cucumber'
require 'cucumber/rspec/doubles'

OPTIONS = YAML.load_file(File.join(__dir__, 'environments.yml')).fetch(ENV.fetch('PRODUCT'))

Before('@slow_process') do
  aruba.config.io_wait_timeout = 90
  aruba.config.exit_timeout = 90
end

Before('@libzypplocked') do
  `echo $PPID > /var/run/zypp.pid`
end

After('@libzypplocked') do
  `rm /var/run/zypp.pid`
end
