SUSEConnect(5) - SUSE Customer Center registration tool config file
===================================================================

## DESCRIPTION
</etc/SUSEConnect> is the config file for the SUSE registration tool SUSEConnect.  This file allows the registration of the base product on the system.  NB: registration of extensions is not supported using this file. 

## FORMAT
The file is in [YAML][yaml-spec] format.

Example:

`---`

`regcode: <regcode>`

`url: https://scc.suse.com`

`language: en`

Each line of the file specifies a single parameter.  The fields are as follows
  * url: URL of the registration server.  Corresponds to the --url argument to SUSEConnect
  * regcode: Registration code to use for the base product on the system
  * language: (optional) Language code to use for error messages

 
## AUTHOR
SUSE Linux Products GmbH <scc-feedback@suse.de>
 
## LINKS
[SUSE Customer Center][scc]

## SEE ALSO
SUSEConnect(8)
