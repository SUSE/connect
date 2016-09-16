#!/bin/sh -xe
gem build suse-connect.gemspec &&
rake build &&
zypper --non-interactive --no-gpg-checks in /var/tmp/build-root/SLE_12-x86_64/home/abuild/rpmbuild/RPMS/x86_64/* &&
cucumber /tmp/connect/features/activation.feature /tmp/connect/features/activation_errors.feature
