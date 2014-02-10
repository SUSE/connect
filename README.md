[![Build Status](https://secure.travis-ci.org/SUSE/connect.png?branch=master)](https://travis-ci.org/SUSE/connect)
[![Code Climate](https://codeclimate.com/github/SUSE/connect.png)](https://codeclimate.com/github/SUSE/connect)
[![Coverage Status](https://coveralls.io/repos/SUSE/connect/badge.png?branch=master)](https://coveralls.io/r/SUSE/connect)

# SUSEConnect

```
Usage: SUSEConnect [options]
    -h, --host [HOST]                Connection host.
    -p, --port [PORT]                Connection port.
    -t, --token [TOKEN]              Registration token.
    -k, --insecure                   Skip ssl verification (insecure).
        --skip-ssl                   Skip SSL encryption (use with caution).

Common options:
    -d, --dry-mode                   Dry mode. Does not make any changes to the system.
    -v, --verbose                    Run verbosely.
        --version                    Print version
        --help                       Show this message.

```


# Building

At first you need to build the gem:

`> gem build suse-connect.gemspec`

This gem can already be installed and used. To create a RPM from this gem you should run:

`> gem2rpm -l -o package/SUSEConnect.spec -t package/SUSEconnect.spec.erb suse-connect-0.0.2.gem`

This will create a .spec file in the package/ subfolder which then can be used to build the package:

`> cd package; osc -A https://api.suse.de build SLE_12 x86_64 --no-verify`




