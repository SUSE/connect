require 'chefspec'
require 'chefspec/deprecations'

describe 'connect::packages' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.node.set[:connect][:packages] = {
      'gcc' => true,
      'git' => true,
      'ruby-devel' => true,
      'osc' => false
    }
    runner.converge('connect::packages')
  end

  let(:osc_package) do
    'osc-0.145.0-131.1.x86_64.rpm'
  end

  it 'should install all required packages' do
    expect(chef_run).to install_package('gcc')
    expect(chef_run).to install_package('ruby-devel')
    expect(chef_run).to install_package('git')
  end

  it 'should remove unneeded packages' do
    expect(chef_run).to remove_package('osc')
  end

  it 'downloads osc package' do
    expect(chef_run).to create_remote_file_if_missing("/tmp/#{osc_package}")
  end

  it 'installs osc package' do
    zypp_cmd = 'zypper --non-interactive --no-gpg-checks --quiet install --auto-agree-with-licenses'
    expect(chef_run).to run_execute('install osc package').with(
      command: "#{zypp_cmd} /tmp/#{osc_package}"
    )
  end
end
