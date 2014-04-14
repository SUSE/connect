git '/tmp/connect' do
  repository 'https://github.com/SUSE/connect.git'
  reference 'master'
  action 'sync'
end

execute 'bundle_instal' do
  command 'sudo bundle install'
  cwd node[:connect][:project]
end

execute 'build_suse_connect_gem' do
  command 'gem build suse-connect.gemspec'
  cwd node[:connect][:project]
end

execute 'install_suse_connect_gem' do
  command 'gem install suse-connect-*'
  cwd node[:connect][:project]
end

execute 'cp suse-connect-*.gem package/' do
  command 'cp suse-connect-*.gem package/'
  cwd node[:connect][:project]
end

execute 'gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb suse-connect-*.gem' do
  command 'gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb suse-connect-*.gem'
  cwd "#{node[:connect][:project]}/package"
end

execute 'create man page for SUSEConnect' do
  command 'ronn --roff --manual SUSEConnect --pipe ../README.md > SUSEConnect.1 && gzip SUSEConnect.1'
  not_if { ::File.exist?('/tmp/connect/package/SUSEConnect.1.gz')}
  cwd "#{node[:connect][:project]}/package"
end
