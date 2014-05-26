require 'chefspec'

describe 'connect::integration_tests' do
  let(:chef_run) { ChefSpec::Runner.new.converge 'connect::integration_tests' }

  it 'runs cucumber tests' do
    expect(chef_run).to run_execute('integration testing').with(
      command: 'sudo LOCAL_SERVER=https://scc.suse.com cucumber /tmp/connect/features/integration.feature',
      cwd: '/tmp/connect'
    )
  end
end
