execute 'integration testing' do
  command 'sudo LOCAL_SERVER=https://scc.suse.com cucumber /tmp/connect/features/integration.feature'
  cwd node[:connect][:project]
  user 'vagrant'
  group 'users'
end
