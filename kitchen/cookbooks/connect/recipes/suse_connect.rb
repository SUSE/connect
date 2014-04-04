git '/tmp/connect' do
  repository 'https://github.com/SUSE/connect.git'
  reference 'master'
  action 'sync'
end

execute 'bundle_instal' do
  command 'bundle install'
  cwd '/tmp/connect'
end

execute 'build_suse_connect_gem' do
  command 'gem build suse-connect.gemspec'
  cwd '/tmp/connect'
end

execute 'install_suse_connect_gem' do
  command 'gem install suse-connect-*'
  cwd '/tmp/connect'
end
