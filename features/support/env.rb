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
  `echo $PPID > /var/run/zypp.pid`
end

After('@libzypplocked') do
  `rm /var/run/zypp.pid`
end

Before('@yast') do
  # needed only for the YaST integration tests
  require 'yast'
  require 'registration/registration'
end
