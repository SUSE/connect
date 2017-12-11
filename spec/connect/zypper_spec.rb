require 'spec_helper'

describe SUSE::Connect::Zypper do
  before(:each) do
    allow(SUSE::Connect::System).to receive(:filesystem_root).and_return nil
    allow(Object).to receive(:system).and_return true
  end

  subject { SUSE::Connect::Zypper }
  let(:status) { double('Process Status', exitstatus: 0) }
  include_context 'shared lets'

  describe '.installed_products' do
    context :sle11 do
      context :sp3 do
        let(:xml) { File.read('spec/fixtures/product_valid_sle11sp3.xml') }

        before do
          args = 'zypper --no-remote --no-refresh --xmlout --non-interactive products -i'
          allow(Open3).to receive(:capture3).with(shared_env_hash, args).and_return([xml, '', status])
        end

        it 'returns valid list of products based on proper XML' do
          expect(subject.installed_products.first.identifier).to eq 'SUSE_SLES'
        end

        it 'returns valid version' do
          expect(subject.installed_products.first.version).to eq '11.3'
        end

        it 'returns valid arch' do
          expect(subject.installed_products.first.arch).to eq 'x86_64'
        end

        it 'returns proper base product' do
          expect(subject.base_product.identifier).to eq 'SUSE_SLES'
        end
      end
    end

    context :sle12 do
      context :sp0 do
        let(:xml) { File.read('spec/fixtures/product_valid_sle12sp0.xml') }

        before do
          args = 'zypper --no-remote --no-refresh --xmlout --non-interactive products -i'
          allow(Open3).to receive(:capture3).with(shared_env_hash, args).and_return([xml, '', status])
        end

        it 'returns valid name' do
          expect(subject.installed_products.first.identifier).to eq 'SLES'
        end

        it 'returns valid version' do
          expect(subject.installed_products.first.version).to eq '12'
        end

        it 'returns valid arch' do
          expect(subject.installed_products.first.arch).to eq 'x86_64'
        end

        it 'returns proper base product' do
          expect(subject.base_product.identifier).to eq 'SLES'
        end
      end
    end
  end

  describe '.enable_repository' do
    let(:repository) { 'repository' }

    it 'enables zypper repository' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, "zypper --non-interactive modifyrepo -e #{repository}").and_return(['', '', status])
      subject.enable_repository(repository)
    end

    it 'raise an exception if repository not found' do
      exception = "SUSE::Connect::ZypperError: Repository #{repository} not found."
      expect(Open3).to receive(:capture3).with(shared_env_hash, "zypper --non-interactive modifyrepo -e #{repository}").and_raise(exception)
      expect { subject.enable_repository(repository) }.to raise_error("SUSE::Connect::ZypperError: Repository #{repository} not found.")
    end
  end

  describe '.disable_repository' do
    let(:repository) { 'repository' }

    it 'enables zypper repository' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, "zypper --non-interactive modifyrepo -d #{repository}").and_return(['', '', status])
      subject.disable_repository(repository)
    end

    it 'raise an exception if repository not found' do
      exception = "SUSE::Connect::ZypperError: Repository #{repository} not found."
      expect(Open3).to receive(:capture3).with(shared_env_hash, "zypper --non-interactive modifyrepo -d #{repository}").and_raise(exception)
      expect { subject.disable_repository(repository) }.to raise_error("SUSE::Connect::ZypperError: Repository #{repository} not found.")
    end
  end

  describe '.repositories' do
    let(:zypper_repo_output) { File.read('spec/fixtures/zypper_repositories.xml') }
    let(:zypper_no_repo_output) { File.read('spec/fixtures/zypper_no_repositories.xml') }
    let(:args) { 'zypper --xmlout --non-interactive repos -d' }

    it 'lists all defined repositories' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).at_least(1).and_return([zypper_repo_output, '', status])
      expect(subject.repositories.size).to eq 4
      expect(subject.repositories.first.keys).to match_array([:alias, :name, :type, :priority, :enabled, :autorefresh, :gpgcheck, :url])
      expect(subject.repositories.map {|service| service[:name] }).to match_array(%w[SLES12-Debuginfo-Pool SLES12-Debuginfo-Updates SLES12-Pool SLES12-Updates])
    end

    it 'returns empty list when zypper has no repositories' do
      status = double('Process Status', exitstatus: 6)
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).at_least(1).and_return([zypper_no_repo_output, '', status])
      expect(subject.repositories.size).to eq 0
    end
  end

  describe '.add_service' do
    let(:service_name) { 'valid_service' }
    let(:service_url)  { 'http://example.com' }
    let(:args) { "zypper --non-interactive addservice -t ris #{service_url} '#{service_name}'" }

    before :each do
      allow(Zypper).to receive(:remove_service).with(service_name)
      allow(Zypper).to receive(:enable_service_autorefresh).with(service_name)
      allow(Zypper).to receive(:write_service_credentials).with(service_name)
      allow(Zypper).to receive(:refresh_service)
    end

    it 'adds service' do
      expect(Zypper).to receive(:remove_service).with(service_name)
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      expect(Zypper).to receive(:enable_service_autorefresh).with(service_name)
      expect(Zypper).to receive(:write_service_credentials).with(service_name)
      expect(Zypper).to receive(:refresh_service).with(service_name)

      subject.add_service(service_url, service_name)
    end

    it 'sets autorefresh flag' do
      expect(Zypper).to receive(:enable_service_autorefresh).with(service_name)
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      subject.add_service(service_url, service_name)
    end

    it 'calls zypper with proper arguments --root case' do
      args = "zypper --root '/path/to/root' --non-interactive addservice -t ris #{service_url} '#{service_name}'"

      allow(SUSE::Connect::System).to receive(:filesystem_root).and_return '/path/to/root'
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      subject.add_service(service_url, service_name)
    end

    it 'escapes shell parameters' do
      malformed_service_url = "#{service_url};id"
      malformed_service_name = "#{service_name};id"
      escaped_service_url = Shellwords.escape(malformed_service_url)
      escaped_service_name = Shellwords.escape(malformed_service_name)

      args = "zypper --non-interactive addservice -t ris #{escaped_service_url} '#{escaped_service_name}'"

      expect(Zypper).to receive(:remove_service).with(malformed_service_name)
      expect(Zypper).to receive(:enable_service_autorefresh).with(malformed_service_name)
      expect(Zypper).to receive(:write_service_credentials).with(malformed_service_name)
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      subject.add_service(malformed_service_url, malformed_service_name)
    end
  end

  describe '.remove_service' do
    it 'calls zypper with proper arguments' do
      args = "zypper --non-interactive removeservice 'branding'"
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      expect(Zypper).to receive(:remove_service_credentials).with('branding')

      subject.remove_service('branding')
    end

    it 'calls zypper with proper arguments --root case' do
      allow(SUSE::Connect::System).to receive(:filesystem_root).and_return '/path/to/root'

      args = "zypper --root '/path/to/root' --non-interactive removeservice 'branding'"
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])

      subject.remove_service('branding')
    end
  end

  describe '.refresh_service' do
    it 'calls zypper with proper arguments' do
      service_name = 'SLES'
      expect(Open3).to receive(:capture3).with(shared_env_hash, "zypper --non-interactive refs #{service_name}").and_return(['', '', status])
      subject.refresh_service service_name
    end
  end

  describe '.refresh_all_services' do
    it 'calls zypper with proper arguments' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'zypper --non-interactive refs').and_return(['', '', status])
      subject.refresh_all_services
    end
  end

  describe '.find_products' do
    let(:zypper_sles_product_search) { File.read('spec/fixtures/zypper_sles_product_search.xml') }
    let(:zypper_sles_product_search_not_found) { File.read('spec/fixtures/zypper_sles_product_search_not_found.xml') }
    let(:args) { "zypper --xmlout --no-refresh --non-interactive search --match-exact -s -t product #{identifier}" }

    context 'when product exists' do
      let(:identifier) { 'SLES' }

      before do
        allow(Open3).to receive(:capture3).with(shared_env_hash, args).at_least(1).and_return([zypper_sles_product_search, '', status])
      end

      it 'finds products by identifier' do
        products = subject.find_products(identifier)
        expect(products.size).to eq 2
        expect(products.map {|p| p[:repository] }).to match_array(%w[SLES-12 SLES12-Pool])
      end
    end

    context 'when product does not exist' do
      let(:identifier) { 'fake' }
      # zypper exits with status 104 when it doesn't find a product
      let(:failed_status) { double('Process Status', exitstatus: 104) }

      before do
        $stdout = StringIO.new
        allow(Open3).to receive(:capture3).with(shared_env_hash, args).at_least(1).and_return([zypper_sles_product_search_not_found, '', failed_status])
      end

      after(:all) do
        $stdout = STDOUT
      end

      it 'returns an empty array' do
        products = subject.find_products(identifier)
        expect(products).to match_array([])
        expect($stdout.string).not_to match(/command '#{args}' failed/)
      end
    end
  end

  describe '.remove_all_suse_services' do
    let(:zypper_services_output) { File.read('spec/fixtures/zypper_services.xml') }
    let(:service_args) { 'zypper --xmlout --non-interactive services -d' }

    before do
      allow(Open3).to receive(:capture3).with(shared_env_hash, service_args).at_least(1).and_return([zypper_services_output, '', status])
    end

    it 'removes SCC installed services' do
      args = "zypper --non-interactive removeservice 'scc_sles12'"

      allow_any_instance_of(SUSE::Connect::Config).to receive(:url).and_return('https://scc.suse.com')
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])

      subject.remove_all_suse_services
    end

    it 'removes SMT installed services' do
      args = "zypper --non-interactive removeservice 'smt_sles12'"

      allow_any_instance_of(SUSE::Connect::Config).to receive(:url).and_return('https://smt.suse.de')
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])

      subject.remove_all_suse_services
    end

    it 'removes legacy services' do
      args = "zypper --non-interactive removeservice 'legacy_sles12'"

      allow_any_instance_of(SUSE::Connect::Config).to receive(:url).and_return('https://legacy.suse.de')
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])

      subject.remove_all_suse_services
    end
  end

  describe '.remove_service_credentials' do
    let(:service_name) { 'SLES_12_Service' }
    let(:service_credentials_dir) { SUSE::Connect::Credentials::DEFAULT_CREDENTIALS_DIR }
    let(:service_credentials_file) { File.join(service_credentials_dir, service_name) }

    it 'removes zypper service credentials' do
      expect(File).to receive(:join).with(service_credentials_dir, service_name).and_return(service_credentials_file)
      expect(File).to receive(:exist?).with(service_credentials_file).and_return(true)
      expect(File).to receive(:delete).with(service_credentials_file).and_return(true)

      subject.remove_service_credentials(service_name)
    end
  end

  describe '.services' do
    let(:zypper_services_output) { File.read('spec/fixtures/zypper_services.xml') }
    let(:args) { 'zypper --xmlout --non-interactive services -d' }

    before do
      allow(Open3).to receive(:capture3).with(shared_env_hash, args).at_least(1).and_return([zypper_services_output, '', status])
    end

    it 'lists all defined services.' do
      expect(subject.services.size).to eq 3
      expect(subject.services.first.keys).to match_array([:alias, :autorefresh, :enabled, :name, :type, :url])
      expect(subject.services.map {|service| service[:name] }).to match_array(%w[scc_sles12 smt_sles12 legacy_sles12])
    end
  end

  describe '.refresh' do
    it 'calls zypper with proper arguments' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'zypper --non-interactive refresh').and_return(['', '', status])
      subject.refresh
    end

    it 'calls zypper with proper arguments --root case' do
      allow(SUSE::Connect::System).to receive(:filesystem_root).and_return '/path/to/root'

      expect(Open3).to receive(:capture3).with(shared_env_hash, "zypper --root '/path/to/root' --non-interactive refresh")
        .and_return(['', '', status])
      subject.refresh
    end
  end

  describe '.enable_service_autorefresh' do
    let(:service_name) { 'zypper_service' }
    it 'calls zypper with proper arguments' do
      args = "zypper --non-interactive modifyservice -r #{service_name}"
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      subject.enable_service_autorefresh service_name
    end

    it 'calls zypper with proper arguments' do
      allow(SUSE::Connect::System).to receive(:filesystem_root).and_return '/path/to/root'
      args = "zypper --root '/path/to/root' --non-interactive modifyservice -r #{service_name}"
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      subject.enable_service_autorefresh service_name
    end
  end

  describe '.refresh_services' do
    it 'calls zypper with proper arguments' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'zypper --non-interactive refresh-services -r').and_return(['', '', status])
      subject.refresh_services
    end

    it 'calls zypper with proper arguments' do
      allow(SUSE::Connect::System).to receive(:filesystem_root).and_return '/path/to/root'

      expect(Open3).to receive(:capture3).with(shared_env_hash, "zypper --root '/path/to/root' --non-interactive refresh-services -r")
        .and_return(['', '', status])
      subject.refresh_services
    end
  end

  describe '.base_product' do
    let :parsed_products do
      [
        SUSE::Connect::Zypper::Product.new(isbase: '1', name: 'SLES', productline: 'SLE_productline1', registerrelease: ''),
        SUSE::Connect::Zypper::Product.new(isbase: '2', name: 'Cloud', productline: 'SLE_productline2', registerrelease: '')
      ]
    end

    before do
      allow(subject).to receive(:installed_products).and_return parsed_products
      allow_any_instance_of(Credentials).to receive(:write).and_return true
    end

    it 'should return first product from installed product which is base' do
      expect(subject.base_product).to eq(parsed_products.first)
    end

    it 'raises CannotDetectBaseProduct if cant get base system from list of installed products' do
      product = double('Product', isbase: false)
      allow(Zypper).to receive(:installed_products).and_return([product])
      expect { Zypper.base_product }.to raise_error(CannotDetectBaseProduct)
    end
  end

  describe '.install_release_package' do
    it 'calls the command' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'zypper --no-refresh --non-interactive install --no-recommends --auto-agree-with-product-licenses -t product opensuse') # rubocop:disable LineLength
                                         .and_return(['', '', status])
      subject.install_release_package('opensuse')
    end
  end

  describe '.remove_release_package' do
    it 'calls the command' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'zypper --no-refresh --non-interactive remove -t product opensuse')
                                         .and_return(['', '', status])
      subject.remove_release_package('opensuse')
    end
  end

  describe '.set_release_version' do
    it 'sets the release version' do
      release_version = '5'
      zypper_cmd = "zypper --non-interactive --releasever #{release_version} ref -f"
      expect(Open3).to receive(:capture3).with(shared_env_hash, zypper_cmd).and_return(['', '', status])
      subject.set_release_version(release_version)
    end
  end

  describe '.write_base_credentials' do
    mock_dry_file

    before do
      allow_any_instance_of(Credentials).to receive(:write).and_return true
    end

    it 'should call write_base_credentials_file' do
      expect(Credentials).to receive(:new).with('dummy', 'tummy', Credentials::GLOBAL_CREDENTIALS_FILE).and_call_original
      subject.write_base_credentials('dummy', 'tummy')
    end
  end

  describe '.write_service_credentials' do
    mock_dry_file

    before do
      allow_any_instance_of(Credentials).to receive(:write).and_return true
    end

    it 'extracts username and password from system credentials' do
      expect(System).to receive(:credentials)
      subject.write_service_credentials('turbo')
    end

    it 'creates a file with source name' do
      expect(Credentials).to receive(:new).with('dummy', 'tummy', 'turbo').and_call_original
      subject.write_service_credentials('turbo')
    end
  end

  describe '.distro_target' do
    it 'return zypper targetos output' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'zypper targetos').and_return(['openSUSE-13.1-x86_64', '', status])
      expect(Zypper.distro_target).to eq 'openSUSE-13.1-x86_64'
    end

    it 'return zypper targetos output --root case' do
      allow(SUSE::Connect::System).to receive(:filesystem_root).and_return '/path/to/root'

      args = "zypper --root '/path/to/root' targetos"
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['openSUSE-13.1-x86_64', '', status])
      expect(Zypper.distro_target).to eq 'openSUSE-13.1-x86_64'
    end
  end
end
