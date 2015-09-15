remote_file '/root/.regcode' do
  source 'http://username:password@gaffer.suse.de:9999/files/.regcode'
  action :create
  user 'root'
  group 'root'
end

execute 'integration testing' do
  command 'cucumber'
  cwd node[:connect][:project]
  user 'root'
  group 'root'
end
