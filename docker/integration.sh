#!/bin/sh -xe
if [ -z $PRODUCT ]
then
  echo "PRODUCT env var for integration testing not set!"
  exit 1
fi

rake build[$PRODUCT] &&
zypper --non-interactive --no-gpg-checks in /var/tmp/build-root/$PRODUCT-x86_64/home/abuild/rpmbuild/RPMS/x86_64/* &&
cucumber /tmp/connect/features/activation.feature /tmp/connect/features/activation_errors.feature
