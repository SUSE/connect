execute 'integration testing' do
  command 'cucumber /tmp/connect/features/integration.feature'
  cwd node[:connect][:project]
  user 'root'
  group 'root'
end
