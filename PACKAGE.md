# SUSEConnect Development

Install the needed libraries:

`sudo bundle install`

At first you need to build the gem:

`> gem build suse-connect.gemspec`

This gem can already be installed and used. To create a RPM from this gem you need to create the .spec file:

```
> cp suse-connect-*.gem package/
> cd package
> gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb suse-connect-0.0.2.gem
```

To create the man page do:

`> ronn --roff --manual 'SUSEConnect' --pipe ../README.md > SUSEConnect.1 && gzip SUSEConnect.1`

To build the package:

`> osc -A https://api.suse.de build SLE_12 x86_64 --no-verify`




