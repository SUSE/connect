remote_file "/tmp/osc-0.144.1-130.1.x86_64.rpm" do
  source "http://download.opensuse.org/repositories/openSUSE:/Tools/SLE_11_SP3/x86_64/osc-0.144.1-130.1.x86_64.rpm"
  mode 0644
  action :create_if_missing
end

execute 'install osc package' do
  command 'zypper --non-interactive --no-gpg-checks --quiet install --auto-agree-with-licenses /tmp/osc-0.144.1-130.1.x86_64.rpm'
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
