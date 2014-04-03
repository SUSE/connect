execute 'clean_zypper_repos' do
  command "zypper repos | awk '{if (NR > 2) {print $1}}' | xargs zypper removerepo {}"
end

execute "add_sle_12_repo" do
  command "zypper --non-interactive ar http://download.suse.de/ibs/SUSE:/SLE-12:/GA/standard/ SLE-12-standard"
end
