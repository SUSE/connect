#!/bin/sh -xe
cd /tmp/connect
rspec
rubocop
cucumber
