require 'chefspec'

describe 'connect::repositories' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.converge('connect::repositories')
  end

  it 'removes all zypper repositories' do
    expect(chef_run).to run_execute('clean_zypper_repos').with(command: "zypper repos | awk '{if (NR > 2) {print $1}}' | xargs zypper removerepo {}")
  end

   it 'adds SLE-12 GA repositroey' do
    expect(chef_run).to run_execute('add_sle_12_repo').with(command: 'zypper --non-interactive ar http://download.suse.de/ibs/SUSE:/SLE-12:/GA/standard/ SLE-12-standard')
  end
end

