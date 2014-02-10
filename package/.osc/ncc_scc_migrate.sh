#!/bin/sh

if [ -s /etc/zypp/credentials.d/NCCcredentials ]; then
   # setting this to be able to run the script from within a zypper transaction
   export ZYPP_READONLY_HACK=true
   # TODO implement migration scenario in SUSEConnect and SCC API
   # TODO the idea is to call product activate with token=migration
   # SUSEConnect --ncc
else
   echo "No NCC registration found. Cannot automatically migrate system to SCC"
fi
