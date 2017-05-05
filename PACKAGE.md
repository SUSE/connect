# SUSEConnect Packaging

## TL;DR

You can use `rake build` to perform all the manual steps described below (no version bump will be done).
After you've build the package locally and are happy with the result - commit the changes to IBS.

## Step 1. Update gem version

You need to update the gem version (see `bundle exec bump --help` for the list of available options):

```bash
bundle exec bump patch
```
This also commits the version change. So `git show HEAD` shows you the new version number.

## Step 2. Refresh your package

Before you start to update files in the `package` folder, make sure it is clean and updated:
```
osc status
osc up
```

If you run into some merge conflict, you can delete everything in our package folder (except the `.gitignore`), then do
`iosc checkout Devel:SCC:suseconnect` which creates a subfolder from where you can move all files to your `package` folder.
`iosc status` afterwards to make sure you have no unwanted changes anymore.

## Step 3. Update package version

Update the `Version:` declaration in `SUSEConnect.spec` to the new value manually.

Please also update `SUSEConnect.changes` file with a list of new features in master since the last version update. You can do it manually or with the command:
```
osc vc
```

After you've commited your sources, make sure that a new git tag (looking like `v0.2.88`) has been also created and pushed. It is highly advised to use [signed tags](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work); use `git tag -s v0.2.88 -m "Version 0.2.88"` to create those.

## Step 4. Build package files

Then build the gem and copy it to package-building directory:

```bash
gem build suse-connect.gemspec
cp suse-connect-*.gem package/
```

To update the man pages for the package please do:

```bash
cd package;
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8  && gzip -f SUSEConnect.8
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5  && gzip -f SUSEConnect.5
```

## Step 5. Build the package

Build the package for SLES 12 versions:

```bash
osc build SLE_12 x86_64 --no-verify
osc build SLE_12_SP1 x86_64 --no-verify
osc build SLE_12_SP2 x86_64 --no-verify
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


## Step 7. Submit Maintenance Request

To get the maintenance request accepted, each changelog entry needs to reference a bug or feature
request with `bnc#123` or `fate#123`.

To submit a maintenance request, issue this command in the console:

__OpenSUSE Factory__ `osc sr systemsmanagement:SCC SUSEConnect openSUSE:Factory --no-cleanup`

You can check the status of your requests [here](https://build.opensuse.org/package/requests/systemsmanagement:SCC/SUSEConnect).

After it was accepted in OpenSUSE Factory, don't forget to create maintenance request on [Internal Build service](https://build.suse.de/package/show/Devel:SCC:suseconnect/SUSEConnect). 
