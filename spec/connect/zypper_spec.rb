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
          args = 'zypper --no-refresh --xmlout --non-interactive products -i'
          Open3.should_receive(:capture3).with(shared_env_hash, args).and_return([xml, '', status])
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
          args = 'zypper --no-refresh --xmlout --non-interactive products -i'
          Open3.should_receive(:capture3).with(shared_env_hash, args).and_return([xml, '', status])
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
    let(:zypper_output) { File.read('spec/fixtures/zypper_repositories.xml') }
    let(:args) { 'zypper --xmlout --non-interactive repos -d' }

    before do
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).at_least(1).and_return([zypper_output, '', status])
    end

    it 'lists all defined repositories' do
      expect(subject.repositories.size).to eq 4
      expect(subject.repositories.first.keys).to match_array([:alias, :name, :type, :priority, :enabled, :autorefresh, :gpgcheck, :url])
      expect(subject.repositories.map {|service| service[:name] }).to match_array(%w{SLES12-Debuginfo-Pool SLES12-Debuginfo-Updates SLES12-Pool SLES12-Updates})
    end
  end

  describe '.add_service' do
    describe 'calls zypper with proper arguments' do
      it 'adds service' do
        addservice_args = "zypper --non-interactive addservice -t ris http://example.com 'branding'"
        autorefresh_args = 'zypper --non-interactive modifyservice -r http://example.com'
        expect(Open3).to receive(:capture3).with(shared_env_hash, addservice_args).and_return(['', '', status])
        allow(Open3).to receive(:capture3).with(shared_env_hash, autorefresh_args).and_return(['', '', status])
        subject.add_service('http://example.com', 'branding')
      end

      it 'sets autorefresh flag' do
        addservice_args = "zypper --non-interactive addservice -t ris http://example.com 'branding'"
        autorefresh_args = 'zypper --non-interactive modifyservice -r http://example.com'
        allow(Open3).to receive(:capture3).with(shared_env_hash, addservice_args).and_return(['', '', status])
        expect(Open3).to receive(:capture3).with(shared_env_hash, autorefresh_args).and_return(['', '', status])
        subject.add_service('http://example.com', 'branding')
      end
    end

    it 'escapes shell parameters' do
      args = "zypper --non-interactive addservice -t ris http://example.com\\;id 'branding'"
      autorefresh_args = 'zypper --non-interactive modifyservice -r http://example.com\\;id'
      allow(Open3).to receive(:capture3).with(shared_env_hash, autorefresh_args).and_return(['', '', status])
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])
      subject.add_service('http://example.com;id', 'branding')
    end

    it 'calls zypper with proper arguments --root case' do
      allow(SUSE::Connect::System).to receive(:filesystem_root).and_return '/path/to/root'

      args = "zypper --root '/path/to/root' --non-interactive addservice -t ris http://example.com 'branding'"
      autorefresh_args = "zypper --root '/path/to/root' --non-interactive modifyservice -r http://example.com"
      allow(Open3).to receive(:capture3).with(shared_env_hash, autorefresh_args).and_return(['', '', status])
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).and_return(['', '', status])

      subject.add_service('http://example.com', 'branding')
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

  describe '.remove_all_suse_services' do
    let(:zypper_services_output) { File.read('spec/fixtures/zypper_services.xml') }
    let(:service_args) { 'zypper --xmlout --non-interactive services -d' }

    before do
      expect(Open3).to receive(:capture3).with(shared_env_hash, service_args).at_least(1).and_return([zypper_services_output, '', status])
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
      expect(Open3).to receive(:capture3).with(shared_env_hash, args).at_least(1).and_return([zypper_services_output, '', status])
    end

    it 'lists all defined services.' do
      expect(subject.services.size).to eq 3
      expect(subject.services.first.keys).to match_array([:alias, :autorefresh, :enabled, :name, :type, :url])
      expect(subject.services.map {|service| service[:name] }).to match_array(%w{scc_sles12 smt_sles12 legacy_sles12})
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
      subject.stub(installed_products: parsed_products)
      Credentials.any_instance.stub(:write)
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

  describe '.write_base_credentials' do
    mock_dry_file

    before do
      allow_any_instance_of(Credentials).to receive(:write).and_return true
    end

    it 'should call write_base_credentials_file' do
      Credentials.should_receive(:new).with('dummy', 'tummy', Credentials::GLOBAL_CREDENTIALS_FILE).and_call_original
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
