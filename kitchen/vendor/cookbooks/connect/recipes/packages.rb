node[:connect][:packages].each do |name, install|
  if install
    package name do
      action :install
      not_if "rpm -q #{name}"
    end
  else
    package name do
      action :remove
    end
  end
end
