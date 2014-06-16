require 'chefspec'

describe 'connect::repositories' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new
    runner.converge('connect::repositories')
  end

  it 'removes all zypper repositories' do
    expect(chef_run).to run_execute('clean_zypper_repos').with(
      command: "zypper repos | awk '{if (NR > 2) {print $1}}' | xargs zypper removerepo {}"
    )
  end

  it 'adds SLE-12 GA repository' do
    expect(chef_run).to run_execute('add_sle_12_repo').with(
      command: 'zypper --non-interactive ar http://download.suse.de/ibs/SUSE:/SLE-12:/GA/standard/ SLE-12-standard'
    )
  end

  it 'adds openSUSE:/Tools/SLE_11_SP3 repository for osc package' do
    expect(chef_run).to run_execute('add_osc_repo').with(
      command: 'zypper --non-interactive ar http://download.opensuse.org/repositories/openSUSE:/Tools/SLE_11_SP3/ OSC'
    )
  end

  it 'adds SUSE CA certificates repository' do
    expect(chef_run).to run_execute('add_suse_ca-certs_repo').with(
      command: 'zypper --non-interactive ar --refresh http://download.suse.de/ibs/SUSE:/CA/SLE-11/ SUSE-CA-CERTS'
    )
  end
end
