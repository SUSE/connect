require 'chefspec'
require 'chefspec/deprecations'

describe 'connect::packages' do

  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.node.set[:connect][:packages] = { 'osc' => true, 'git' => true, 'java' => false }
    runner.converge('connect::packages')
  end

  it 'should install all required packages' do
    expect(chef_run).to install_package('osc')
    expect(chef_run).to install_package('git')
  end

  it 'should remove unneeded packages' do
    expect(chef_run).to remove_package('java')
  end
end
