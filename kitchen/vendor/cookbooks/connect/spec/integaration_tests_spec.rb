require 'chefspec'

describe 'connect::integration_tests' do
  let(:chef_run) { ChefSpec::Runner.new.converge 'connect::integration_tests' }

  it 'creates .regcode file for later usage' do
    expect(chef_run).to create_remote_file('/root/.regcode').with(
      source: 'http://username:password@gaffer.suse.de:9999/files/.regcode',
      user: 'root',
      group: 'root'
    )

  end

  it 'runs cucumber tests' do
    expect(chef_run).to run_execute('integration testing').with(
      command: 'cucumber /tmp/connect/features/integration.feature',
      cwd: '/tmp/connect',
      user: 'root',
      group: 'root'
    )
  end
end
