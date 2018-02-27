#!/bin/sh -xe
cd /tmp/connect && rspec
cd /tmp/connect && rubocop
cd /tmp/connect && cucumber
