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
    expect(chef_run).to run_execute('sudo bundle install').with(
      command: 'sudo bundle install',
      cwd: '/tmp/connect'
    )
  end

  it 'builds SUSEConnect gem from source' do
    expect(chef_run).to run_execute('build SUSEConnect gem').with(
      command: 'gem build suse-connect.gemspec',
      cwd: '/tmp/connect'
    )
  end

  it 'installs SUSEConnect gem' do
    expect(chef_run).to run_execute('install SUSEConnect gem').with(
      command: 'gem install suse-connect-*',
      cwd: '/tmp/connect'
    )
  end

  it 'builds SUSEConnect RPM' do
    python_path = '$PYTHONPATH:/usr/lib64/python2.6/site-packages/'
    osc_build = 'osc -A https://api.suse.de build SLE_12 x86_64 --no-verify'

    expect(chef_run).to run_execute('build SUSEConnect RPM').with(
      command: "su vagrant -l -c 'cd /tmp/connect/package && export PYTHONPATH=#{python_path} && #{osc_build}'",
      cwd: '/tmp/connect/package'
    )
  end
end
