While using SUSEConnect, you might encounter SSL errors if your system is not set-up correctly

### Sample errors:

- `unable to get local issuer certificate`
- `certificate verify failed`

### Possible solutions 

#### Installed certificates tampered with

Something might be wrong with the installed certificates. The certificates used by Ruby/SUSEConnect are installed by the `ca-certificates` package. Make sure nothing is tampering with the certificates installed by that package.

#### Custom certificate

You might need to install a custom certificate (for example, you connect to the internet via a proxy which modifies SUSE's certificate, or you have an SMT installation with a custom certificate).

In this case:

1. Place the custom certificate (crt or pem file) into `/etc/pki/trust/anchors`
2. Run `update-ca-certificates`

The `update-ca-certificates` tool, provided by the ca-certificates package, grabs custom certificates from that location and then copies them to an array of different other locations in the system, so that they can be seen by different programs (Ruby, Java, curl, web browsers, etc). For details see `man update-ca-certificates`.