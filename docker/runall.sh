#!/bin/sh -xe
cd /tmp/connect && su nobody -c rspec
cd /tmp/connect && su nobody -c rubocop
cd /tmp/connect && cucumber
