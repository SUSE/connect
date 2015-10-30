# SUSEConnect Packaging

You can use `rake build` to perform all the manual steps described below (no version bump will be done).
After you've build the package locally and are happy with the result - commit the changes to IBS.

## TL;DR

Install the needed libraries:

```bash
sudo bundle install
```

At first you need to update the gem version (see `bundle exec bump --help` for the list of available options):

```bash
bundle exec bump patch
```

The gem version will be as a package version by `gem2rpm` tool, so without the bump package won't be updated.

Please also update `SUSEConnect.changes` file with a list of new features in master since the last version update.


Then build the gem:

```bash
gem build suse-connect.gemspec
```

This gem can already be installed and used. To create a RPM from this gem you
need to create the .spec file.  You need to use gem2rpm to do this, and using
the specifically patched version from SLES12 or openSUSE 13.2+, because only those support the --config option.

```bash
cp suse-connect-*.gem package/
cd package
gem2rpm --config gem2rpm.yml -l -o SUSEConnect.spec \
    -t /usr/share/doc/packages/ruby2.1-rubygem-gem2rpm/sles12.spec.erb \
    suse-connect-*.gem
```

To create the man page do:

```bash
ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8
ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5
```


To build the package:

```bash
osc -A https://api.suse.de build SLE_12 x86_64 --no-verify
```

To submit the package:
```bash
cd package
(optional in .bashrc) alias iosc="osc -A https://api.suse.de"
iosc status / osc -A 'https://api.suse.de'
check for new commits flagged with 'M'
iosc commit / osc -A 'https://api.suse.de' commit
```



