
# CentOS derivatives support

## Versions

* Development done against Fedora 24
  * CentOS 7 does not provide Ruby 2.1 out of the box

## Design Rationale

yum/dnf do not have the concept of ZYpp services, therefore:

* One needs to manually add and remove repositories
* or...implement a [yum/dnf plugin](https://dnf.readthedocs.io/en/latest/api_plugins.html)

  The plugin would read the service and add the needed repositories to the yum API.

  *CONCERNS*:
  * Plugin would need to talk to SCC and parse XML data outside of the SUSEConnect codebase
    (dnf plugins are Python classes).
  * Plugin still needs to do some book-keeping on the repositories
  * Giving that it is only a couple of repos, and no migrations, probably not worth it

Handling the services ourselves would only mean we have to read it. Taking advantage that we can define multiple repos per .repo file means we can write all .repos in a service in the same file.

## Implementation

* dnf has poor repository access from the command line, a python helper is used to transport data to SUSEConnect.
  (Alternative is to parse ini files, which requires a parser and to handle all dnf config options)

* Simple enable/disable of repositories using [config-manager](https://docs-old.fedoraproject.org/en-US/Fedora/23/html/System_Administrators_Guide/sec-Managing_DNF_Repositories.html)

## Other resources

* RES suseRegister branch
  `svn diff http://svn.suse.de/svn/SmallProjects/trunk/registerTool http://svn.suse.de/svn/SmallProjects/branches/branch_RH/`

