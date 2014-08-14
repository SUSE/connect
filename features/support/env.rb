$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')

require 'suse/connect'
require 'aruba/cucumber'
require 'cucumber/rspec/doubles'

Before('@slow_process') do
  @aruba_io_wait_seconds = 90
  @aruba_timeout_seconds = 90
end

Before('@libzypplocked') do
  `echo $$ > /var/run/zypp.pid && kill -19 $$`
end

After('@libzypplocked') do
  `read PID < /var/run/zypp.pid  && kill -18 $PID && rm /var/run/zypp.pid`
end


