require 'chefspec'

describe 'connect::rubygems' do
  let(:chef_run) { ChefSpec::Runner.new.converge 'connect::suse_connect' }

  it 'clones connect github repo' do
    expect(chef_run).to sync_git('/tmp/connect').with(
      repository: 'https://github.com/SUSE/connect.git',
      reference: 'master'
    )
  end

  it 'installs required gems' do
    expect(chef_run).to run_execute('bundle_instal').with(
      command: 'sudo bundle install',
      cwd: '/tmp/connect'
    )
  end

  it 'builds suse_connect gem from source' do
    expect(chef_run).to run_execute('build_suse_connect_gem').with(
      command: 'gem build suse-connect.gemspec',
      cwd: '/tmp/connect'
    )
  end

  it 'installs suse_connect gem' do
    expect(chef_run).to run_execute('install_suse_connect_gem').with(
      command: 'gem install suse-connect-*',
      cwd: '/tmp/connect'
    )
  end
end
