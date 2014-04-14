require 'chefspec'
require 'chefspec/deprecations'

describe 'connect::packages' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.node.set[:connect][:packages] = {
      'gcc' => true,
      'git' => true,
      'ruby-devel' => true,
      'osc' => true,
      'SUSEConnect' => false
    }
    runner.converge('connect::packages')
  end

  before do
    stub_command("rpm -q gcc").and_return(false)
    stub_command("rpm -q git").and_return(false)
    stub_command("rpm -q osc").and_return(false)
    stub_command("rpm -q build").and_return(false)
    stub_command("rpm -q ruby-devel").and_return(false)
  end

  it 'should install all required packages' do
    expect(chef_run).to install_package('gcc')
    expect(chef_run).to install_package('git')
    expect(chef_run).to install_package('osc')
    expect(chef_run).to install_package('ruby-devel')
  end

  it 'should remove unneeded packages' do
    expect(chef_run).to remove_package('SUSEConnect')
  end
end
