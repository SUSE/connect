git '/tmp/connect' do
  repository 'https://github.com/SUSE/connect.git'
  reference 'review_140718_fix_failing_language_integration_test'
  action 'sync'
  user 'vagrant'
  group 'users'
end

execute 'sudo bundle install' do
  command 'sudo bundle install'
  cwd node[:connect][:project]
  user 'vagrant'
  group 'users'
end

execute 'remove stale gems' do
  command 'rm -f *.gem; rm -f package/*.gem'
  cwd node[:connect][:project]
  user 'vagrant'
  group 'users'
end

execute 'build SUSEConnect gem' do
  command 'gem build suse-connect.gemspec'
  cwd node[:connect][:project]
  user 'vagrant'
  group 'users'
end

# NOTE: Disabled because of RPM testing
# execute 'install SUSEConnect gem' do
#   command 'gem install suse-connect-*'
#   cwd node[:connect][:project]
# end

execute 'cp suse-connect-*.gem package/' do
  command 'cp suse-connect-*.gem package/'
  cwd node[:connect][:project]
  user 'vagrant'
end

execute 'gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb suse-connect-*.gem' do
  command 'gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb suse-connect-*.gem'
  cwd "#{node[:connect][:project]}/package"
  user 'vagrant'
end

execute 'create man pages for SUSEConnect' do
  command 'ronn --roff --manual SUSEConnect --pipe SUSEConnect.8.ronn > SUSEConnect.8 && gzip -f SUSEConnect.8 && ' \
          'ronn --roff --manual SUSEConnect --pipe SUSEConnect.5.ronn > SUSEConnect.5 && gzip -f SUSEConnect.5'
  cwd "#{node[:connect][:project]}/package"
  user 'vagrant'
end

python_path = '$PYTHONPATH:/usr/lib64/python2.6/site-packages/'
osc_url = 'https://api.suse.de'
osc_build = "osc -A #{osc_url} build #{node[:connect][:osc][:project]} #{node[:connect][:osc][:arch]} --no-verify"

execute 'build SUSEConnect RPM' do
  command "export PYTHONPATH=#{python_path}; echo 2|#{osc_build}"
  cwd "#{node[:connect][:project]}/package"
end

zypper_options = '--non-interactive  --no-gpg-checks'
execute 'install SUSEConnect RPM' do
  command "zypper #{zypper_options} in /var/tmp/build-root/SLE_12-x86_64/home/abuild/rpmbuild/RPMS/x86_64/*"
  cwd "#{node[:connect][:project]}/package"
end
