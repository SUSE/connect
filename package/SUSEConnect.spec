#
# spec file for package SUSEConnect
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

# Please submit bugfixes or comments via https://bugzilla.suse.com/
#

Name:           SUSEConnect
Version:        0.2.33
Release:        0
%define mod_name suse-connect
%define mod_full_name %{mod_name}-%{version}

Requires:       coreutils, util-linux, net-tools, hwinfo, zypper, ca-certificates-mozilla
Requires:       zypper >= 1.11.32
Conflicts:      suseRegister, yast2-registration < 3.1.129.7

Obsoletes:      ruby2.1-rubygem-suse-connect < %{version}
Provides:       %{rb_default_ruby_suffix}-rubygem-suse-connect = %{version}

%ifarch x86_64
Requires:       dmidecode
%endif

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  %{ruby >= 2.0}

Url:            https://github.com/SUSE/connect

Source:         %{mod_full_name}.gem
Source1:        %{name}.5.gz
Source2:        %{name}.8.gz
Source3:        %{name}.example

Summary:        Utility to register a system with the SUSE Customer Center
License:        LGPL-2.1
Group:          System/Management
PreReq:         update-alternatives

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
gem install --verbose --local --build-root=%{buildroot} -f --no-ri --no-rdoc ./%{mod_full_name}.gem
mkdir %{buildroot}%{_sbindir}
mv %{buildroot}%{_bindir}/%{name}.%{rb_default_ruby_suffix} %{buildroot}%{_sbindir}/%{name}
ln -s %{_sbindir}/%{name} %{buildroot}%{_bindir}/%{name}

install -D -m 644 %_sourcedir/SUSEConnect.5.gz %{buildroot}%_mandir/man5/SUSEConnect.5.gz
install -D -m 644 %_sourcedir/SUSEConnect.8.gz %{buildroot}%_mandir/man8/SUSEConnect.8.gz
install -D -m 644 %_sourcedir/SUSEConnect.example %{buildroot}%_sysconfdir/SUSEConnect.example

touch %{buildroot}%_sysconfdir/SUSEConnect
mkdir -p %{buildroot}%_sysconfdir/zypp/credentials.d/
touch %{buildroot}%_sysconfdir/zypp/credentials.d/SCCcredentials

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

# remove stale update-alternatives config left by previous split, versioned packaging of SUSEConnect
if update-alternatives --config SUSEConnect  &> /dev/null ; then
  update-alternatives --quiet --remove-all SUSEConnect
fi

%files
%defattr(-,root,root,-)
%{_sbindir}/SUSEConnect
%{_bindir}/SUSEConnect
%{gem_base}/gems/%{mod_full_name}/
%{gem_base}/cache/%{mod_full_name}.gem
%{gem_base}/specifications/%{mod_full_name}.gemspec

%doc %{_mandir}/man5/SUSEConnect.5.gz
%doc %{_mandir}/man8/SUSEConnect.8.gz

%config(noreplace) %ghost %{_sysconfdir}/SUSEConnect
%config %{_sysconfdir}/SUSEConnect.example
%config %dir %{_sysconfdir}/zypp/
%config %dir %{_sysconfdir}/zypp/credentials.d/
%config(noreplace) %ghost %{_sysconfdir}/zypp/credentials.d/SCCcredentials

%changelog
