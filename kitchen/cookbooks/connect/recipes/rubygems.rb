file '/etc/gemrc' do
  content "gem: --no-ri --no-rdoc\n"
end

node[:connect][:gems].each_pair do |gem_name, gem_version|
  gem_package gem_name do
    options('--no-ri --no-rdoc')
    version gem_version
  end
end
