shared_examples_for SUSE::Connect::Archs::Generic do |unknown_system|

  let(:credentials_file) { Credentials::GLOBAL_CREDENTIALS_FILE }

  before(:each) do
    allow_any_instance_of(Object).to receive(:system).and_return true
  end

  it 'returns system architecture' do
    allow(subject).to receive(:execute).with('uname -i', false).and_return 'blob'
    expect(subject.arch).to eql 'blob'
  end

  describe '.credentials' do

    context :credentials_exist do

      let :stub_ncc_cred_file do
        stub_creds_file = double('me_file')
        stub_creds_file.stub(:close)
        stub_creds_file
      end

      before do
        File.stub(:exist?).with(credentials_file).and_return(true)
      end

      it 'should raise MalformedSccCredentialsFile if cannot parse lines' do
        File.stub(:read).with(credentials_file).and_return("me\nfe")
        expect { subject.credentials }
        .to raise_error MalformedSccCredentialsFile, 'Cannot parse credentials file'
      end

      it 'should return username and password' do
        File.stub(:read).with(credentials_file).and_return("username=bill\npassword=nevermore")
        subject.credentials.username.should eq 'bill'
        subject.credentials.password.should eq 'nevermore'
      end

    end

    context :credentials_not_exist do

      before(:each) do
        File.should_receive(:exist?).with(credentials_file).and_return(false)
      end

      it 'should produce log message' do
        subject.credentials.should be_nil
      end

    end

    context :remove_credentials do

      before(:each) do
        subject.should_receive(:credentials?).and_return(true)
        File.should_receive(:delete).with(credentials_file).and_return(true)
      end

      it 'should remove credentials file' do
        subject.remove_credentials.should be true
      end

    end
  end

  describe '.credentials?' do

    it 'returns false if no credentials' do
      subject.stub(credentials: nil)
      subject.credentials?.should be false
    end

    it 'returns true if credentials exist' do
      subject.stub(credentials: Credentials.new('123456789', 'ABCDEF'))
      subject.credentials?.should be true
    end
  end

  describe '.activated_base_product?' do

    it 'returns false if sytem does not have a credentials' do
      subject.stub(:credentials? => false)
      subject.activated_base_product?.should be false
    end

    it 'returns false if sytem has credentials but not activated' do
      subject.stub(credentials?: true)
      Zypper.stub(:base_product)
      expect(SUSE::Connect::Status).to receive(:activated_products).and_return([])
      subject.activated_base_product?.should be false
    end

    it 'returns true if sytem has credentials and activated' do
      subject.stub(credentials?: true)
      product = Zypper::Product.new name: 'OpenSUSE'

      expect(Zypper).to receive(:base_product).and_return(product)
      expect(SUSE::Connect::Status).to receive(:activated_products).and_return([product])
      subject.activated_base_product?.should be true
    end
  end

  describe '.add_service' do

    before(:each) do
      Zypper.stub(:write_service_credentials)
      Credentials.any_instance.stub(:write)
    end

    let :mock_service do
      Remote::Service.new('name' => 'JiYoKo', 'url' => 'furl', 'product' => {})
    end

    it 'adds zypper service to the system' do
      Zypper.should_receive(:remove_service).with('JiYoKo')
      Zypper.should_receive(:add_service).with('furl', 'JiYoKo')
      Zypper.should_receive(:write_service_credentials).with('JiYoKo')
      Zypper.should_receive(:refresh_services).exactly(1).times
      subject.add_service mock_service
    end

    it 'raises an ArgumentError exception' do
      expect { subject.add_service 'Service' }.to raise_error(ArgumentError, 'only Remote::Service accepted')
    end
  end

  describe '.hostname' do
    context :hostname_detected do
      it 'returns hostname' do
        Socket.stub(:gethostname => 'vargan')
        subject.hostname.should eq 'vargan'
      end
    end

    context :hostname_nil do
      it 'returns first private ip' do
        stubbed_ip_address_list = [Addrinfo.ip('127.0.0.1'), Addrinfo.ip('192.168.42.42')]
        Socket.stub(:ip_address_list => stubbed_ip_address_list)
        Socket.stub(:gethostname => nil)
        subject.hostname.should eq '192.168.42.42'
      end
    end

    context :hostname_is_none do
      it 'returns first private ip' do
        stubbed_ip_address_list = [Addrinfo.ip('127.0.0.1'), Addrinfo.ip('192.168.42.42')]
        Socket.stub(:ip_address_list => stubbed_ip_address_list)
        Socket.stub(:gethostname => '(none)')
        subject.hostname.should eq '192.168.42.42'
      end
    end
  end

  describe '.hwinfo' do

    it 'returns only hostname for other architectures' do
      allow(subject).to receive(:hostname).and_return('blue_gene')
      allow(subject).to receive(:arch).and_return('blob')
      expect(subject.hwinfo).to eq(hostname: 'blue_gene', arch: 'blob')
    end

  end if unknown_system

end
