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

The `Version:` declaration in `SUSEConnect.spec` needs to be updated manually to the new value.

Please also update `SUSEConnect.changes` file with a list of new features in master since the last version update.


Then build the gem:

```bash
gem build suse-connect.gemspec
```

And copy it to the package-building directory:

```bash
cp suse-connect-*.gem package/
```

To update the man pages for the package please do:

```bash
ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8
ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5
```

To finally build the package:

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
