require 'spec_helper'

describe SUSE::Connect::System do
  let(:credentials_file) { Credentials::GLOBAL_CREDENTIALS_FILE }

  before(:each) do
    allow_any_instance_of(Object).to receive(:system).and_return true
  end

  subject { SUSE::Connect::System }

  describe '.hwinfo' do
    it 'collects basic hwinfo for x86/x86_64 systems ' do
      expect(SUSE::Connect::HwInfo::Base).to receive(:info).and_return({})
      subject.hwinfo
    end
  end

  describe '.credentials' do
    context :credentials_exist do
      let :stub_ncc_cred_file do
        stub_creds_file = double('me_file')
        allow(stub_creds_file).to receive(:close)
        stub_creds_file
      end

      before do
        allow(File).to receive(:exist?).with(credentials_file).and_return(true)
      end

      it 'should raise MalformedSccCredentialsFile if cannot parse lines' do
        allow(File).to receive(:read).with(credentials_file).and_return("me\nfe")
        expect { subject.credentials }
          .to raise_error MalformedSccCredentialsFile, 'Cannot parse credentials file'
      end

      it 'should return username and password' do
        allow(File).to receive(:read).with(credentials_file).and_return("username=bill\npassword=nevermore")

        expect(subject.credentials.username).to eq 'bill'
        expect(subject.credentials.password).to eq 'nevermore'
      end
    end

    context :credentials_not_exist do
      before(:each) do
        expect(File).to receive(:exist?).with(credentials_file).and_return(false)
      end

      it 'should produce log message' do
        expect(subject.credentials).to be_nil
      end
    end

    context :remove_credentials do
      before(:each) do
        expect(subject).to receive(:credentials?).and_return(true)
        expect(File).to receive(:delete).with(credentials_file).and_return(true)
      end

      it 'should remove credentials file' do
        expect(subject.remove_credentials).to be true
      end
    end
  end

  describe '.credentials?' do
    it 'returns false if no credentials' do
      allow(subject).to receive_messages(credentials: nil)
      expect(subject.credentials?).to be false
    end

    it 'returns true if credentials exist' do
      allow(subject).to receive_messages(credentials: Credentials.new('123456789', 'ABCDEF'))
      expect(subject.credentials?).to be true
    end
  end

  describe '.activated_base_product?' do
    it 'returns false if sytem does not have a credentials' do
      allow(subject).to receive_messages(:credentials? => false)
      expect(subject.activated_base_product?).to be false
    end

    it 'returns false if sytem has credentials but not activated' do
      allow(subject).to receive_messages(credentials?: true)
      allow(Zypper).to receive(:base_product)
      expect(SUSE::Connect::Status).to receive(:activated_products).and_return([])
      expect(subject.activated_base_product?).to be false
    end

    it 'returns true if sytem has credentials and activated' do
      allow(subject).to receive_messages(credentials?: true)
      product = Zypper::Product.new name: 'OpenSUSE'

      expect(Zypper).to receive(:base_product).and_return(product)
      expect(SUSE::Connect::Status).to receive(:activated_products).and_return([product])
      expect(subject.activated_base_product?).to be true
    end
  end

  describe '.add_service' do
    before(:each) do
      allow(Zypper).to receive(:write_service_credentials)
      allow_any_instance_of(Credentials).to receive(:write)
    end

    let :mock_service do
      Remote::Service.new('name' => 'JiYoKo', 'url' => 'furl', 'product' => {})
    end

    it 'adds zypper service to the system' do
      expect(Zypper).to receive(:add_service).with('furl', 'JiYoKo')
      subject.add_service mock_service
    end

    it 'raises an ArgumentError exception' do
      expect { subject.add_service 'Service' }.to raise_error(ArgumentError, 'only Remote::Service accepted')
    end
  end

  describe '.cleanup!' do
    it 'removes system credentials and zypper services which were added by SUSEConnect' do
      expect(Zypper).to receive(:remove_all_suse_services).and_return(true)
      expect(System).to receive(:remove_credentials).and_return(true)

      subject.cleanup!
    end
  end

  describe '.hostname' do
    context :hostname_detected do
      it 'returns hostname' do
        allow(Socket).to receive_messages(:gethostname => 'vargan')
        expect(subject.hostname).to eq 'vargan'
      end
    end

    context :hostname_nil do
      it 'returns first private ip' do
        stubbed_ip_address_list = [Addrinfo.ip('127.0.0.1'), Addrinfo.ip('192.168.42.100'), Addrinfo.ip('192.168.42.42')]
        allow(Socket).to receive_messages(:ip_address_list => stubbed_ip_address_list)
        allow(Socket).to receive_messages(:gethostname => nil)
        expect(subject.hostname).to eq '192.168.42.100'
      end
    end

    context :hostname_is_none do
      it 'returns first private ip' do
        stubbed_ip_address_list = [Addrinfo.ip('127.0.0.1'), Addrinfo.ip('192.168.42.42')]
        allow(Socket).to receive_messages(:ip_address_list => stubbed_ip_address_list)
        allow(Socket).to receive_messages(:gethostname => '(none)')
        expect(subject.hostname).to eq '192.168.42.42'
      end
    end

    context 'hostname and private ip is nil' do
      it 'returns nil' do
        stubbed_ip_address_list = [Addrinfo.ip('127.0.0.1'), Addrinfo.ip('44.0.0.69')]
        allow(Socket).to receive_messages(:ip_address_list => stubbed_ip_address_list)
        allow(Socket).to receive_messages(:gethostname => nil)
        expect(subject.hostname).to eq nil
      end
    end
  end

  describe '.read_file' do
    it 'reads file' do
      instance_file_path = 'spec/fixtures/instance_data.xml'
      expect(subject.read_file(instance_file_path)).to eq File.read(instance_file_path)
    end

    it 'raises on unreadable file' do
      expect { subject.read_file('/not_available_path') }.to raise_error(FileError, 'File not found')
    end
  end
end
