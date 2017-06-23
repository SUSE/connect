#!/bin/sh -xe

# make sure we always test with the latest version of zypper
zypper --non-interactive up zypper

cd /tmp/connect && su nobody -c rspec
cd /tmp/connect && su nobody -c rubocop
cd /tmp/connect && cucumber
