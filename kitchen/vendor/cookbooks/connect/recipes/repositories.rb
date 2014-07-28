execute 'clean_zypper_repos' do
  command "zypper repos | awk '{if (NR > 2) {print $1}}' | xargs zypper removerepo {}"
end

execute 'add_sle_12_repo' do
  command 'zypper --non-interactive ar http://download.suse.de/ibs/SUSE:/SLE-12:/GA/standard/ SLE-12-standard'
end

execute 'add_darix_gem2rpm_repo' do
  command 'zypper --non-interactive ar http://download.suse.de/ibs/home:/darix:/ruby/SLE_12/ darix-gem2rpm'
end

execute 'add_osc_repo' do
  command 'zypper --non-interactive ar http://download.opensuse.org/repositories/openSUSE:/Tools/SLE_11_SP3/ OSC'
end
