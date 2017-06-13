# SUSEConnect Packaging

## TL;DR

You can use `rake build` instead of steps 2 to 5.
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
cd package_ibs
osc status
osc up
cd ../package_obs
osc status
osc up
```

If you run into some merge conflict, you can delete everything in our package folder (except the `.gitignore`), then do
`osc checkout systemsmanagement:SCC` which creates a subfolder from where you can move all files to your `package` folder.
`osc status` afterwards to make sure you have no unwanted changes anymore.

## Step 3. Update package version

Update the `Version:` declaration in both `SUSEConnect.spec` to the new value manually.

Please also update `SUSEConnect.changes` file with a list of new features in master since the last version update. You can do it manually or with the command:
```
cd package_ibs
osc vc
cd ../package_obs
osc vc
```

After you've commited your sources, make sure that a new git tag (looking like `v0.3.88`) has been also created and pushed. It is highly advised to use [signed tags](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work); use `git tag -s v0.3.88 -m "Version 0.3.88"` to create those.

## Step 4. Build package files

Then build the gem and copy it to package-building directory:

```bash
gem build suse-connect.gemspec
cp suse-connect-*.gem package_obs/
cp suse-connect-*.gem package_ibs/
```

To update the man pages for the package please do:

```bash
cd package_ibs
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8  && gzip -f SUSEConnect.8
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5  && gzip -f SUSEConnect.5
cd ../package_obs
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.8.ronn > SUSEConnect.8  && gzip -f SUSEConnect.8
ronn --roff --manual SUSEConnect --pipe ../SUSEConnect.5.ronn > SUSEConnect.5  && gzip -f SUSEConnect.5
```

## Step 5. Build the package

Build the package for SLES 12 versions:

```bash
osc build SLE_12 x86_64 --no-verify
osc build SLE_12_SP1 x86_64 --no-verify
osc build SLE_12_SP2 x86_64 --no-verify
osc build SLE_12_SP3 x86_64 --no-verify
```

Please consult the corresponding [IBS page](https://build.opensuse.org/package/show/systemsmanagement:SCC/SUSEConnect) for the full list of available targets.

## Step 6. Commiting the package

To submit the package:
```bash
cd package_ibs
osc status
```

Check for new commits flagged with 'M'.
It should typically be enough to run `osc ar` to add new and delete removed files from the subsequent osc checkin. Then finalize the revision:

```bash
osc commit
```

Repeat the same with `package_obs`

## Step 7. Submit Requests to OpenSUSE Factory and IBS

To get a maintenance request accepted, each changelog entry needs to reference a bug or feature
request with `bnc#123` or `fate#123`.

### Factory First

To submit a request to openSUSE Factory, issue this commands in the console:

```bash
cd package_obs
osc sr systemsmanagement:SCC SUSEConnect openSUSE:Factory --no-cleanup
```


### Internal Build Service

```bash
cd package_ibs
osc mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12:Update --no-cleanup
osc mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12-SP1:Update --no-cleanup
osc mr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12-SP2:Update --no-cleanup

osc sr Devel:SCC:suseconnect SUSEConnect SUSE:SLE-12-SP3:GA --no-cleanup
```


You can check the status of your requests [here](https://build.opensuse.org/package/requests/systemsmanagement:SCC/SUSEConnect) and [here](https://build.suse.de/package/requests/Devel:SCC:suseconnect/SUSEConnect).
