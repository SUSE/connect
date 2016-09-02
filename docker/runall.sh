#!/bin/sh -xe
cd /tmp/connect && su nobody -c gem build suse-connect.gemspec
cd /tmp/connect && su nobody -c rake build
#cd /tmp/connect && su nobody -c rubocop
#cd /tmp/connect && cucumber
