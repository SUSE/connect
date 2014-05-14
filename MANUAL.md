SUSEConnect(8) - SUSE Customer Center registration tool
=======================================================

## SYNOPSIS

`SUSEConnect [<optional>...] -p PRODUCT

## DESCRIPTION

Register SUSE Linux Enterprise installations with the SUSE Customer Center.
Registration allows access to software repositories including updates
and allows online management of subscriptions and organizations

Manage subscriptions at https://scc.suse.com

## OPTIONS
             @opts.on('-p', '--product [PRODUCT]', 'Activate PRODUCT. Defaults to the base SUSE Linux',
                 '  Enterprise product on this system.',
                 '  Product identifiers can be obtained with \'zypper products\'',
                 '  Format: <name>-<version>-<architecture>') do |opt|

      @opts.on('-r', '--regcode [REGCODE]', 'Subscription registration code for the',
                 '  product to be registered.',
                 '  Relates that product to the specified subscription,',
                 '  and enables software repositories for that product') do |opt|

        @opts.on('-k', '--insecure', 'Skip SSL verification (insecure).') do |opt|
        @opts.on('--url [URL]', 'URL of registration server (e.g. https://scc.suse.com).') do |opt|
        @opts.on('-d', '--dry-run', 'only print what would be done') do |opt|
        @opts.on('--version', 'print program version') do
        @opts.on('-v', '--verbose', 'provide verbose output') do |opt|
        @opts.on('-l [LANG]', '--language [LANG]', 'translate error messages into one of LANG which is a',
                 '  comma-separated list of ISO 639-1 codes') do |opt|
        @opts.on_tail('-h', '--help', 'show this message') do

## FILES

## SEE-ALSO
