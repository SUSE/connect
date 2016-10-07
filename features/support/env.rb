$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

require 'suse/connect'
require 'aruba/cucumber'
require 'cucumber/rspec/doubles'

Before('@slow_process') do
  @aruba_io_wait_seconds = 90
  @aruba_timeout_seconds = 90
end

Before('@libzypplocked') do
  # this should put the pid of the cucumber process into the lockfile
  @old_product_env_var_contents = ENV['PRODUCT']
  ENV['PRODUCT'] = SUSE::Connect::Zypper.base_product.identifier + '_' + SUSE::Connect::Zypper.base_product.version
  `echo $PPID > /var/run/zypp.pid`
end

After('@libzypplocked') do
  `rm /var/run/zypp.pid`
  ENV['PRODUCT'] = @old_product_env_var_contents
end
