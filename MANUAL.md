SUSEConnect(8) - SUSE Customer Center registration tool
=======================================================

## SYNOPSIS

`SUSEConnect [<optional>...] -p PRODUCT

## DESCRIPTION

Register SUSE Linux Enterprise installations with the SUSE Customer Center.
Registration allows access to software repositories including updates
and allows online management of subscriptions and organizations.

By default, SUSEConnect registers the base SUSE Linux Enterprise product
installed on a system by querying zypper.  It can also be used to register
extensions that have been installed after system installation from physical media.

To register extensions, use the `--product <PRODUCT-IDENTIFIER>` option together 
with the product identifier of the extension, obtained with `zypper products`
  
Manage subscriptions at https://scc.suse.com

## OPTIONS
  * `-p`, `--product <PRODUCT>`:
    Activate PRODUCT. Defaults to the base SUSE Linux Enterprise product
    on this system. Product identifiers can be obtained with 'zypper products'.
    Format: <name>-<version>-<architecture>

  * `-r`, `--regcode <REGCODE>`:
    Subscription registration code for the product to be registered.
    Relates that product to the specified subscription and enables software
    repositories for that product.

  * `-k`, `--insecure`:
    Skip SSL verification (insecure)

  * `--url <URL>`:
    URL of registration server (e.g. https://scc.suse.com).

  * `-d`, `--dry-run`:
    Only print what would be done

  * `--version`:
    Print program version

  * `-v`, `--verbose`:
    Provide verbose output

  * `-l <LANG>`, `--language <LANG>`:, 'translate error messages into one of LANG which is a',
                 '  comma-separated list of ISO 639-1 codes') do |opt|
        @opts.on_tail('-h', '--help', 'show this message') do

## DIAGNOSTICS
  The following errors may be given on stderr:

## COMPARED TO SUSE_REGISTER
### BEFORE
  `suse_register -a email=<email> -a regcode-sles=<regcode> -L <logfile>`
### AFTER
  `SUSEConnect --url <registration-server-url> -r <regcode> >> <logfile>`

## USE WITH SMT
  SUSEConnect can also be used to register systems with a local SUSE Subscription Management Tool, instead of the SUSE Customer Center.  

## FILES
  * `/etc/SUSEConnect`:
    Configuration file containing server URL etc

## AUTHOR
  SUSE Linux Products GmbH <scc-feedback@suse.de>

## LINKS
  https://scc.suse.com
