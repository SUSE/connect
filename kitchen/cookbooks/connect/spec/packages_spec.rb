require 'chefspec'

describe 'connect::packages' do

  let :chef_run do
    runner = ChefSpec::ChefRunner.new
    # runner.node.set[:connect][:packages] = { 'gobo' => true, 'lobo' => false, 'mobo' => true }
    runner.converge 'connect::packages'
    runner
  end

  it 'should install all required packages' do
    debugger
    %w{ osc }.each do |desired_package|
      chef_run.should install_package desired_package
    end
  end

  it 'should remove unneeded packages' do
    %w{ lobo }.each do |undesired_package|
      chef_run.should remove_package undesired_package
    end
  end
end
