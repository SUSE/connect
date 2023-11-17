[![Build Status](https://github.com/SUSE/connect/actions/workflows/ci_runner.yml/badge.svg)]()
[![Code Climate](https://codeclimate.com/github/SUSE/connect.png)](https://codeclimate.com/github/SUSE/connect)
[![Coverage Status](https://coveralls.io/repos/SUSE/connect/badge.png?branch=master)](https://coveralls.io/r/SUSE/connect)

# SUSEConnect

SUSEConnect is a command line tool for connecting a client system to the SUSE Customer Center.
It will connect the system to your product subscriptions and enable the product repositories/services locally.

SUSEConnect is distributed as RPM for all SUSE distributions and gets built in
the [openSUSE build service](https://build.opensuse.org/package/show/systemsmanagement:SCC/SUSEConnect).

Please visit https://scc.suse.com to see and manage your subscriptions.

SUSEConnect communicates with SCC over this [REST API](https://github.com/SUSE/connect/blob/master/doc/SCC-API-%28Implemented%29.md).

# Rake tasks

```
rake console  # Run console loaded with gem
rake rubocop  # Run Rubocop
rake spec     # Run RSpec
```

# Docker usage

## Build an image (and everytime you change code)

Get $OBS_USER and $OBS_PASSWORD from the CI config.


For SLES12SP0

* `docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.12sp0 -f Dockerfile.12sp0 .`

For SLES12SP1

* `docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.12sp1 -f Dockerfile.12sp1 .`

For SLES12SP2

* `docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.12sp2 -f Dockerfile.12sp2 .`

For SLES12SP3

* `docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.12sp3 -f Dockerfile.12sp3 .`

For SLES15SP0

* `docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.15sp0 -f Dockerfile.15sp0 .`

For SLES15SP3

* `docker build --build-arg OBS_USER=$OBS_USER --build-arg OBS_PASSWORD=$OBS_PASSWORD -t connect.15sp3 -f Dockerfile.15sp3 .`

## Run commands

Note: Substitute `connect.15sp3` with the respective image you've built above.

Open a console

* `docker run --privileged --rm -ti connect.15sp3 /bin/bash`

Run RSpec

* `docker run --privileged --rm -t connect.15sp3 rspec`

Run Cucumber

* `docker run --privileged --rm -t connect.15sp3 cucumber`

Run Rubocop

* `docker run --privileged --rm -t connect.15sp3 rubocop`

Run integration tests & cucumber

* `docker run -e VALID_REGCODE=$VALID_REGCODE -e EXPIRED_REGCODE=$EXPIRED_REGCODE -e NOT_ACTIVATED_REGCODE=$NOT_ACTIVATED_REGCODE --rm -t connect.15sp3 docker/integration.sh`


