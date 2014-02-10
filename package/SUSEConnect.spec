#
# spec file for package rubygem-suse-connect
#
# Copyright (c) 2014 SUSE LINUX Products GmbH, Nuernberg, Germany.
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


Name:           SUSEConnect
Version:        0.0.2
Release:        0
%define mod_name suse-connect
%define mod_full_name %{mod_name}-%{version}

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  ruby-macros >= 1
Requires:       ruby >= 2.0
BuildRequires:  ruby >= 2.0
Url:            https://github.com/SUSE/connect
Summary:        SUSE Connect utility to register a system with the SUSE Customer
License:        LGPL-2.1
Group:          Development/Languages/Ruby

%description
This package provides a command line tool and rubygem library for connecting a
client system to the SUSE Customer Center. It will connect the system to your
product subscriptions and enable the product repositories/services locally.

%prep
#gem_unpack
#if you need patches, apply them here and replace the # with a % sign in the surrounding lines
#gem_build

%build

%install
%gem_install -f --no-rdoc --no-ri

install -D -m 755 %_sourcedir/ncc_scc_migrate.sh %{buildroot}/var/adm/update-scripts/%{name}-%{version}-%{release}-ncc-scc-migrate.sh


%files
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec
/var/adm/update-scripts/%{name}-%{version}-%{release}-ncc-scc-migrate.sh


%changelog
