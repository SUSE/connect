# SUSEConnect Packaging

As a first option you can use `rake build` which will produce all the steps described before
After you build package locally and happy with result - commit changes to IBS instance.

## TL;DR

Install the needed libraries:

`sudo bundle install`

At first you need to build the gem:

`> gem build suse-connect.gemspec`

This gem can already be installed and used. To create a RPM from this gem you
need to create the .spec file.  You need to use gem2rpm to do this, and using
the specifically patched version from SLES12 or devel:languages:ruby:extensions, because this supports
the SLES12 gem packaging standard via the --config option.

```
> cp suse-connect-*.gem package/
> cd package
> gem2rpm --config gem2rpm.yml -l -o SUSEConnect.spec \
    -t /usr/share/doc/packages/rubygem-gem2rpm/sles12.spec.erb \
    suse-connect-*.gem
```

To create the man page do:

`> ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8`
`> ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5`


To build the package:

`> osc -A https://api.suse.de build SLE_12 x86_64 --no-verify`

To submit the package:
```
> cd package
> (optional in .bashrc) alias iosc="osc -A https://api.suse.de"
> iosc status / osc -A 'https://api.suse.de'
> check for new commits flagged with 'M'
> iosc commit / osc -A 'https://api.suse.de' commit 
```



