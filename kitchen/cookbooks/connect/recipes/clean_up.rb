execute 'remove zypper repositories' do
  command "zypper repos | awk '{if (NR > 2) {print $1}}' | xargs zypper removerepo {}"
end

directory "/etc/zypp/locks" do
  action :delete
end
