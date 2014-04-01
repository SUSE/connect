require 'chefspec'

describe 'connect::packages' do

  let :chef_run do
    stub_command("rpm -q git").and_return(true)
    stub_command("rpm -q osc").and_return(false)
    stub_command("rpm -q java").and_return(true)

    runner = ChefSpec::Runner.new
    runner.node.set[:connect][:packages] = { 'osc' => true, 'git' => true, 'java' => false }
    runner.converge 'connect::packages'
    runner
  end

  it 'should install all required packages' do
    chef_run.should install_package 'osc'
    chef_run.should install_package 'git'
  end

  it 'should remove unneeded packages' do
    chef_run.should remove_package 'java'
  end
end
