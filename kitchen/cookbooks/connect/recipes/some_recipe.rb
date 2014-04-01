script "build SUSEConnect package" do
  interpreter "bash"

  cwd "/tmp"
  code <<-EOH
    if [ -d "/tmp/connect" ]
    then
      cd /tmp/connect
      git pull
    else
      git clone https://github.com/SUSE/connect.git
    fi
  EOH

  cwd "/tmp/connect"
  code <<-EOH
    sudo bundle install
    gem build suse-connect.gemspec
    cp suse-connect-*.gem package/
    cd package
    sudo gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb suse-connect-*.gem
    # osc -A https://api.suse.de build SLE_12 x86_64 --no-verify
  EOH
end
