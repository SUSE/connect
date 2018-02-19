#!/bin/sh -xe
if [ -z $PRODUCT ]
then
  echo "PRODUCT env var for integration testing not set!"
  exit 1
fi

rake package:checkout &&
rake package:build_gem &&
rake package:generate_manpages &&
cd package && osc build $PRODUCT x86_64 --no-verify --trust-all-projects && cd .. &&
zypper --non-interactive --no-gpg-checks in /oscbuild/$PRODUCT-x86_64/home/abuild/rpmbuild/RPMS/x86_64/* &&
cucumber /tmp/connect/features/activation.feature \
         /tmp/connect/features/activation_errors.feature \
         /tmp/connect/features/help.feature \
         /tmp/connect/features/version.feature \
         /tmp/connect/features/localization.feature
