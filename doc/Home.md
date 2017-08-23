SUSEConnect is the client side commandline tool to register SUSE systems, activate extensions and migrating systems to another release. It is available for SLES12, SLES12SP1, and SLES12SP2.
The RPM of it is build in the [SUSE Build Service](https://build.suse.de/package/show/Devel:SCC:suseconnect/SUSEConnect). 

Technical information about SUSEConnect:

- [Implemented SCC API](SCC-API-(Implemented).md)   
  Documentation for the implemented API endpoints on SCC that are used by SUSEConnect, SMT and SUSE Manager
- [RFC for SCC API](SCC-API-RFC-(Draft).md)  
  Proposals and drafts of upcoming API implementations
- [YaST abstraction layer](YaST-abstraction-layer.md)  
  Documentation for the class [yast.rb](https://github.com/SUSE/connect/blob/master/lib/suse/connect/yast.rb) that is used by YaST when interacting with the SUSEConnect library.
- [Migration script abstraction layer](Migration-abstraction-layer.md) <br>
  Documentation for the class [migration.rb](https://github.com/SUSE/connect/blob/master/lib/suse/connect/migration.rb) that is used by the zypper-migration script. 

Other resources: 

- [libzypp services](https://doc.opensuse.org/projects/libzypp/HEAD/zypp-services.html)
