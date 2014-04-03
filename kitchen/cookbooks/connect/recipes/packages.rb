package_url = 'http://download.opensuse.org/repositories/devel:/tools:/scm/SLE_11_SP3/x86_64/'
package_name = 'osc-0.145.git.1396510341-84.1.x86_64.rpm'

remote_file '/tmp/osc-0.144.1-130.1.x86_64.rpm' do
  source "#{package_url}#{package_name}"
  mode 0644
  action :create_if_missing
end

zypper_cmd = 'zypper --non-interactive --no-gpg-checks --quiet install --auto-agree-with-licenses'
execute 'install osc package' do
  command "#{zypper_cmd} /tmp/osc-0.144.1-130.1.x86_64.rpm"
end

node[:connect][:packages].each do |name, install|
  if install
    package name do
      action :install
    end
  else
    package name do
      action :remove
    end
  end
end
