#
# spec file for package rubygem-suse-connect
#
# Copyright (c) 2015 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#
#
# This file was generated with a gem2rpm.yml and not just plain gem2rpm.
# All sections marked as MANUAL, license headers, summaries and descriptions
# can be maintained in that file. Please consult this file before editing any
# of those fields
#

Name:           SUSEConnect
Version:        0.2.29
Release:        0
%define mod_name suse-connect
%define mod_full_name %{mod_name}-%{version}

# Revisit if just depending on `ruby` is enough
Requires: coreutils, util-linux, net-tools, hwinfo, zypper, ca-certificates-mozilla
Requires: ruby >= 2.0
Requires: zypper >= 1.11.32
Conflicts: suseRegister, yast2-registration < 3.1.129.7

%ifarch x86_64
Requires: dmidecode
%endif

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  %{ruby >= 2.0}

Url:            https://github.com/SUSE/connect

Source:        %{mod_full_name}.gem
Source1:       %{name}.5.gz
Source2:       %{name}.8.gz
Source3:       %{name}.example

Summary:        SUSE Connect utility to register a system with the SUSE Customer
License:        LGPL-2.1
Group:          Development/Languages/Ruby

%description
This package provides a command line tool and rubygem library for connecting a
client system to the SUSE Customer Center. It will connect the system to your
product subscriptions and enable the product repositories/services locally.

%prep
for s in %{sources}; do
    cp -p $s .
done

%build

%install
gem install --verbose --local --build-root=%{buildroot} \
  --no-rdoc --no-ri \
  %{mod_full_name}.gem

ln -s %{_bindir}/SUSEConnect.%{rb_default_ruby_suffix} %{buildroot}%{_bindir}/SUSEConnect

# Maybe we should mark these as docs with a special macro?
install -D -m 644 %_sourcedir/SUSEConnect.5.gz %{buildroot}%_mandir/man5/SUSEConnect.5.gz
install -D -m 644 %_sourcedir/SUSEConnect.8.gz %{buildroot}%_mandir/man8/SUSEConnect.8.gz
install -D -m 644 %_sourcedir/SUSEConnect.example %{buildroot}%_sysconfdir/SUSEConnect.example

# Why no 5.gz here?
ln -s SUSEConnect.8.gz %{buildroot}%_mandir/man8/SUSEConnect-%{version}.8.gz
mkdir %{buildroot}%{_sbindir}
ln -s %{_bindir}/SUSEConnect %{buildroot}%{_sbindir}/SUSEConnect

%files
%defattr(-,root,root,-)
%{_bindir}/SUSEConnect
%{_sbindir}/SUSEConnect
%{_bindir}/SUSEConnect.%{rb_default_ruby_suffix}
%{gem_base}/gems/%{mod_full_name}/
%{gem_base}/cache/%{mod_full_name}.gem
%{gem_base}/specifications/%{mod_full_name}.gemspec

%{_mandir}/man5/SUSEConnect*
%{_mandir}/man8/SUSEConnect*
%{_sysconfdir}/SUSEConnect.example

%post
if [ -s /etc/zypp/credentials.d/NCCcredentials ] && [ ! -e /etc/zypp/credentials.d/SCCcredentials ]; then
    echo "Imported NCC system credentials to /etc/zypp/credentials.d/SCCcredentials"
    cp /etc/zypp/credentials.d/NCCcredentials /etc/zypp/credentials.d/SCCcredentials
fi

if [ -s /etc/suseRegister.conf ]; then
    reg_server=$(sed -n "s/^[[:space:]]*url[[:space:]]*=[[:space:]]*\(https\?:\/\/[^\/]*\).*/\1/p" /etc/suseRegister.conf)
    # if we have a custom regserver and no SCC config yet, write it
    if [ -n "$reg_server" ] && [ "$reg_server" != "https://secure-www.novell.com" ] && [ ! -e /etc/SUSEConnect ]; then
        echo "Imported /etc/suseRegister.conf registration server url to /etc/SUSEConnect"
        echo "url: $reg_server" > /etc/SUSEConnect
    fi
fi

%changelog
