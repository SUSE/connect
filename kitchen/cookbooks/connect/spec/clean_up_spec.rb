require 'chefspec'

describe 'connect::repositories' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.converge('connect::clean_up')
  end

  it 'removes all zypper repositories' do
    expect(chef_run).to run_execute('remove zypper repositories').with(
      command: "zypper repos | awk '{if (NR > 2) {print $1}}' | xargs zypper removerepo {}"
    )
  end

  it 'deletes a "/etc/zypp/locks" directory' do
    expect(chef_run).to delete_directory('/etc/zypp/locks')
  end
end
