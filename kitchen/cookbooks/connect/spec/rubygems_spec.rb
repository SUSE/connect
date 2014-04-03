require 'chefspec'

describe 'connect::rubygems' do
  let (:chef_run) { ChefSpec::Runner.new.converge 'connect::rubygems' }

  it 'replace systemwide gemrc' do
    expect(chef_run).to create_file('/etc/gemrc').with_content('gem: --no-ri --no-rdoc\n')
  end

  it 'should install desired gems with desired versions' do
    expect(chef_run).to install_gem_package('bundler').with(version: '1.3.5', options: '--no-ri --no-rdoc')
    expect(chef_run).to install_gem_package('gem2rpm').with(version: '0.9.2', options: '--no-ri --no-rdoc')
 end
end
