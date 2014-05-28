execute 'remove zypper repositories' do
  command "zypper repos | awk '{if (NR > 2) {print $1}}' | xargs zypper removerepo {}"
end

execute 'remove zypper services' do
  command "zypper services | awk '{if (NR > 2) {print $1}}' | xargs zypper rs {}"
end

directory '/etc/zypp/locks' do
  action :delete
end
