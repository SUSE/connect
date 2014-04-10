require 'spec_helper'

describe SUSE::Connect::System do

  let(:credentials_file) { Credentials::GLOBAL_CREDENTIALS_FILE }

  before(:each) do
    Object.stub(:system => true)
  end

  subject { SUSE::Connect::System }

  describe '.hwinfo' do

    before do
      Object.should_receive(:'`').with('uname -p').and_return "PowerPC 440\n"
      Object.should_receive(:'`').with('grep "processor" /proc/cpuinfo | wc -l').and_return "250000\n"
      Object.should_receive(:'`').with('uname -i').and_return "x86_64\n"
      Object.should_receive(:'`').with('hostname').and_return "blue_gene\n"
    end

    context :physical do

      it 'should collect basic hwinfo' do
        Object.should_receive(:'`').with('dmidecode').and_return "ahoy\n"
        subject.hwinfo.should eq(
                                   :cpu_type       => 'PowerPC 440',
                                   :cpu_count      => '250000',
                                   :platform_type  => 'x86_64',
                                   :hostname       => 'blue_gene',
                                   :virtualized    => false
                                 )

      end
    end

    context :virtualized do

      it 'should report that system is virtualized' do
        Object.should_receive(:'`').with('dmidecode').and_return "qemu\n"
        subject.hwinfo.should eq(
                                   :cpu_type       => 'PowerPC 440',
                                   :cpu_count      => '250000',
                                   :platform_type  => 'x86_64',
                                   :hostname       => 'blue_gene',
                                   :virtualized    => true
                                 )
      end

    end

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
        subject.should_receive(:registered?).and_return(true)
        File.should_receive(:delete).with(credentials_file).and_return(true)
      end

      it 'should remove credentials file' do
        subject.remove_credentials.should be_true
      end

    end
  end

  describe '.registered?' do

    it 'returns false if credentials are nil' do
      subject.stub(:credentials => nil)
      subject.registered?.should be_false
    end

    it 'returns false if username not prefixed with SCC_' do
      subject.stub(:credentials => Credentials.new('John', 'B'))
      subject.registered?.should be_false
    end

    it 'returns true if credentials exist and username is prefixed with SCC_' do
      subject.stub(:credentials => Credentials.new('SCC_John', 'B'))
      subject.registered?.should be_true
    end
  end

  describe '.add_service' do

    before(:each) do
      Zypper.stub(:write_service_credentials)
      Credentials.any_instance.stub(:write)
    end

    let :mock_service do
      sources = { 'name' => 'url', 'lastname' => 'furl' }
      Service.new(sources, %w{ fehu uruz ansuz }, %w{ green coffee loki })
    end

    it 'removes old service' do
      Zypper.should_receive(:remove_service).with('name')
      Zypper.should_receive(:remove_service).with('lastname')
      subject.add_service mock_service
    end

    it 'add each service from set' do
      Zypper.should_receive(:add_service).with('name', URI('url'))
      Zypper.should_receive(:add_service).with('lastname', URI('furl'))
      subject.add_service mock_service
    end

    it 'enables all repos for this service' do
      Zypper.should_receive(:enable_service_repository).with('name', 'fehu')
      Zypper.should_receive(:enable_service_repository).with('name', 'uruz')
      Zypper.should_receive(:enable_service_repository).with('name', 'ansuz')

      Zypper.should_receive(:enable_service_repository).with('lastname', 'fehu')
      Zypper.should_receive(:enable_service_repository).with('lastname', 'uruz')
      Zypper.should_receive(:enable_service_repository).with('lastname', 'ansuz')

      subject.add_service mock_service
    end

    it 'enables service repository for each of enabled' do
      Zypper.should_receive(:add_service).with('name', URI('url'))
      Zypper.should_receive(:add_service).with('lastname', URI('furl'))
      subject.add_service mock_service
    end

    it 'writes credentials file in corresponding file in credentials.d' do
      Zypper.should_receive(:write_service_credentials).with('name')
      Zypper.should_receive(:write_service_credentials).with('lastname')
      subject.add_service mock_service
    end

    it 'raise if non-Service object passed' do
      expect { subject.add_service('setup') }.to raise_error ArgumentError, 'only Service accepted'
    end

    it 'refresh services' do
      Zypper.should_receive(:refresh_services).exactly(1).times
      subject.add_service mock_service
    end

    it 'set provided repo names to norefresh for each service' do

      Zypper.should_receive(:disable_repository_autorefresh).with('name', 'green')
      Zypper.should_receive(:disable_repository_autorefresh).with('name', 'coffee')
      Zypper.should_receive(:disable_repository_autorefresh).with('name', 'loki')

      Zypper.should_receive(:disable_repository_autorefresh).with('lastname', 'green')
      Zypper.should_receive(:disable_repository_autorefresh).with('lastname', 'coffee')
      Zypper.should_receive(:disable_repository_autorefresh).with('lastname', 'loki')

      subject.add_service mock_service
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

end
