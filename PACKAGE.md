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
You can do that with `osc vc` in the package directory.

After you've commited your sources, make sure that a new git tag (looking like `v0.2.88`) has been also created and pushed. It is highly advised to use [signed tags](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work); use `git tag -s v0.2.88 -m "Version 0.2.88"` to create those.


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
cd package;
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8  && gzip -f SUSEConnect.8
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5  && gzip -f SUSEConnect.5
```

Build the package for SLES12GA:

```bash
osc -A https://api.suse.de build SLE_12 x86_64 --no-verify
```

Building for SLES12SP1:

```bash
osc -A https://api.suse.de build SLE_12_SP1 x86_64 --no-verify
```

Please consult the corresponding [IBS page](https://build.suse.de/project/repositories/Devel:SCC:suseconnect) for the full list of available 


To submit the package:
```bash
cd package
(optional in .bashrc) alias iosc="osc -A https://api.suse.de"
iosc status / osc -A 'https://api.suse.de'
```

Check for new commits flagged with 'M'.
It should typically be enough to run `osc ar` to add new and delete removed files from the subsequent osc checkin.

```bash
iosc commit / osc -A 'https://api.suse.de' commit
```


## Submit Maintenance Request

To get the maintenance request accepted, each changelog entry needs to reference a bug or feature
request with `bnc#123` or `fate#123`.

To submit a maintenance request, issue this command in the console:

```
osc mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12:Update --no-cleanup
```

and for SP1:

```
osc mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12-SP1:Update --no-cleanup
```
and for SP2 (until it's released):

```
osc sr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12-SP2:GA --no-cleanup
```
