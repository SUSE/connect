[![Build Status](https://secure.travis-ci.org/SUSE/connect.png?branch=master)](https://travis-ci.org/SUSE/connect)
[![Dependency Status](https://gemnasium.com/SUSE/connect.svg)](https://gemnasium.com/SUSE/connect)
[![Code Climate](https://codeclimate.com/github/SUSE/connect.png)](https://codeclimate.com/github/SUSE/connect)
[![Coverage Status](https://coveralls.io/repos/SUSE/connect/badge.png?branch=master)](https://coveralls.io/r/SUSE/connect)

# SUSEConnect

is a command line tool for connecting a client system to the SUSE Customer Center.
It will connect the system to your product subscriptions and enable the product repositories/services locally.

SUSEConnect is distributed as RPM for all SUSE distributions and gets built in
the [openSUSE build service](https://build.opensuse.org/package/show/systemsmanagement:SCC/SUSEConnect).

Please visit https://scc.suse.com to see and manage your subscriptions.

SUSEConnect is communicating with SCC over this [REST API](https://github.com/SUSE/connect/blob/master/doc/SCC-API-%28Implemented%29.md).

# Rake tasks

```
rake build    # build locally (see PACKAGE.md for details)
rake bump     # increase version of a gem
rake console  # Run console loaded with gem
rake rubocop  # Run Rubocop
rake spec     # Run RSpec
```

# Docker usage

## Build an image (and everytime you change code)

For SLES12SP0

* `docker build -t connect .`

For SLES12SP1

* `docker build -t connect_sp1 -f Dockerfile.sp1 .`

For SLES12SP2

* `docker build -t connect_sp2 -f Dockerfile.sp2 .`

For SLES12SP3

* `docker build -t connect_sp3 -f Dockerfile.sp3 .`

## Run commands

Open a console

* `docker run --privileged --rm -ti connect /bin/bash`

Run RSpec

* `docker run --privileged --rm -t connect su nobody -c rspec`

Run Cucumber

* `docker run --privileged --rm -t connect cucumber`

Run Rubocop

* `docker run --privileged --rm -t connect su nobody -c rubocop`

Or run whole set of tests together

* `docker run --privileged --rm -t connect sh docker/runall.sh`
