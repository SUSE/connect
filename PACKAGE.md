# SUSEConnect Packaging

## TL;DR

Run `rake package:prepare` to fully prepare the package for checkin to IBS. It runs steps 2 to 4. Make sure to run step 1 before.

## Step 1. Update gem version

You need to update the gem version (see `bundle exec bump --help` for the list of available options):

```bash
bundle exec bump patch
```
This also commits the version change. So `git show HEAD` shows you the new version number.

## Step 2. Refresh your package

The package is built in the OBS at: https://build.opensuse.org/package/show/systemsmanagement:SCC/SUSEConnect

If you've never connected to OBS from your package directory, you need to initialize it first:
```
cd package/; rm SUSEConnect.changes SUSEConnect.example SUSEConnect.spec;
osc co systemsmanagement:SCC SUSEConnect -o .
```

To avoid conflicts between osc versioned files and your updates, make sure it is clean and updated from obs before making changes:

```
cd package
osc status
osc up
```

## Step 3. Update package version

Update the `Version:` declaration in `package/SUSEConnect.spec` to the new value manually.

Please also update `package/SUSEConnect.changes` file with a list of new features in master since the last version update. You can do it manually or with the command:
```
osc vc
```

**Note:** The changelog entry **requires** a reference to a Bugzilla bug (in the form of `bsc#1234`), otherwise maintenance requests will be declined. Even if no bug exists for the particular code change, you need to create one and then reference it here. This is the only way that the patches can appear in the patch finder.

After you've committed your sources, make sure that a new git tag (looking like `v0.3.88`) has been also created and pushed. It is highly advised to use [signed tags](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work); use `git tag -s v0.3.88 -m "Version 0.3.88"` to create those.

## Step 4. Prepare the files for building the package

Then build the gem and copy it to package-building directory:

```bash
gem build suse-connect.gemspec
cp suse-connect-*.gem package/
```

To update the man pages for the package please do:

```bash
cd package
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5
```

## Step 5. Build the package

Build the package for one of the available distributions, eg:

```bash
osc build openSUSE_Leap_42.3 x86_64 --no-verify
osc build SLE_12_SP3 x86_64 --no-verify
osc build SLE_15 x86_64 --no-verify
```

Please consult the corresponding [IBS page](https://build.opensuse.org/package/show/systemsmanagement:SCC/SUSEConnect) for the full list of available targets.

## Step 6. Commiting the package

To submit the package:
```bash
cd package
osc status
```

Check for new commits flagged with 'M'.
It should typically be enough to run `osc ar` to add new and delete removed files from the subsequent osc checkin. Then finalize the revision:

```bash
osc commit
```
## Step 7. Submit Requests to openSUSE Factory and SLES

To get a maintenance request accepted, each changelog entry needs to have at
least one reference to a bug or feature request like `bsc#123` or `fate#123`.

Note: If you want to disable automatic changes made by osc (e.g. License string)
      use the `--no-cleanup` switch. Can be used for commands like `osc mr`, `osc sr`
      and `osc ci`.

### Factory First

To submit a request to openSUSE Factory, issue this commands in the console:

```bash
osc sr systemsmanagement:SCC SUSEConnect openSUSE:Factory
```

### Submit maintenance updates for SLES to the Internal Build Service

#### Get target codesteams where to submit

To checkout in which codestreams the package is currently maintaned, run:

```bash
osc -A https://api.suse.de maintained SUSEConnect
```

For a more detailed view which target codestreams are in which state checkout: [Codestream overview](https://maintenance.suse.de/maintained/?package=SUSEConnect)

#### Submit updates

For each maintained codestream you need to create a new maintenance request:

```bash
osc -A https://api.suse.de mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-15:Update
```

Note: In case the `mr` (maintenance request) command is not working properly,
      try `sr` (submit request) command.


Example:

```bash
$ osc -A https://api.suse.de maintained SUSEConnect
SUSE:SLE-12-SP1:Update/SUSEConnect
SUSE:SLE-12-SP2:Update/SUSEConnect
SUSE:SLE-12-SP3:Update/SUSEConnect
SUSE:SLE-12:Update/SUSEConnect
SUSE:SLE-15:Update/SUSEConnect

$ osc -A https://api.suse.de mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-15:Update
Using target project 'SUSE:Maintenance'
1736456

$ osc -A https://api.suse.de mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12-SP2:Update
Using target project 'SUSE:Maintenance'
164309

$ osc -A https://api.suse.de mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12-SP3:Update
Using target project 'SUSE:Maintenance'
347506

```

You can check the status of your requests [here](https://build.opensuse.org/package/requests/systemsmanagement:SCC/SUSEConnect) and [here](https://build.suse.de/package/requests/Devel:SCC:suseconnect/SUSEConnect).

After your requests got accepted, they still have to pass maintenance testing before they get released to customers. You can check their progress at [maintenance.suse.de](https://maintenance.suse.de/search/?q=SUSEConnect). If you still need help, the maintenance team can be reached at [maint-coord@suse.de](maint-coord@suse.de) or #maintenance on irc.suse.de.
