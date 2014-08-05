node[:connect][:packages].each do |name, install|
  if install
    package name do
      # this checks the package is installed and at the latest version, so no
      # need to check it is already installed manually
      action :upgrade
    end
  else
    package name do
      action :remove
    end
  end
end
