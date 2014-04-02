# script "build SUSEConnect package" do
#   interpreter "bash"

#   cwd "/tmp"
#   code <<-EOH
#     if [ -d "/tmp/connect" ]
#     then
#       cd /tmp/connect
#       git pull
#     else
#       git clone https://github.com/SUSE/connect.git
#     fi
#   EOH

#   cwd "/tmp/connect"
#   code <<-EOH
#     sudo bundle install
#     gem build suse-connect.gemspec
#     cp suse-connect-*.gem package/
#     cd package
#     sudo gem2rpm -l -o SUSEConnect.spec -t SUSEConnect.spec.erb suse-connect-*.gem
#     # osc -A https://api.suse.de build SLE_12 x86_64 --no-verify
#   EOH
# end


git "/tmp/connect" do
  repository "https://github.com/SUSE/connect.git"
  reference "master"
  action "sync"
end

execute "bundle_instal" do
  command "bundle install"
  cwd "/tmp/connect"
  # action :nothing
end

execute "build_suse_connect_gem" do
  command "rake build"
  cwd "/tmp/connect"
  # action :nothing
end

# git '/tmp/connect' do
#   repository 'https://github.com/SUSE/connect.git'
#   action :clone
# end

# git 'specifying the identity attribute' do
#   destination '/tmp/identity_attribute'
#   action :checkout
# end

# # Ensure we have a working git clone
# if '/tmp/connect' does not exist
#   git clone 'https://github.com/SUSE/connect.git'
# end

# # Create branch
# if "deploy" branch does not exist
#   git branch deploy <target revision>
# end

# # Check out branch
# if current_branch != “deploy”
#   git checkout deploy
# end
