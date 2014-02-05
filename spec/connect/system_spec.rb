require 'spec_helper'

describe SUSE::Connect::System do

  before(:each) do
    Object.stub(:system => true)
  end

  subject { SUSE::Connect::System }

  describe '.uuid' do

    context :uuid_file_not_exist do

      it 'should fallback to uuidgen if uuid_file not found' do
        File.stub(:exist?).with(subject::UUIDFILE).and_return(false)
        Object.should_receive(:'`').with(subject::UUIDGEN_LOCATION).and_return 'lambada'
        subject.uuid.should eq 'lambada'
      end

    end

    context :uuid_file_exist do

      it 'should return content of UUIDFILE chomped' do
        File.stub(:exist?).with(subject::UUIDFILE).and_return(false)
        Object.should_receive(:'`').with(subject::UUIDGEN_LOCATION).and_return "lambada\n"
        subject.uuid.should eq 'lambada'
      end

    end

  end

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
        File.should_receive(:exist?).with(subject::NCC_CREDENTIALS_FILE).and_return(true)
        File.should_receive(:new).with(subject::NCC_CREDENTIALS_FILE, 'r').and_return(stub_ncc_cred_file)
      end

      it 'should raise MalformedNccCredentialsFile if cannot parse lines' do
        stub_ncc_cred_file.should_receive(:readlines).and_return(%w{ me fe })
        expect { subject.credentials }
          .to raise_error SUSE::Connect::MalformedNccCredentialsFile, 'Cannot parse credentials file'
      end

      it 'should return username and password' do
        stub_ncc_cred_file.should_receive(:readlines).and_return(%w{ username=bill password=nevermore })
        subject.credentials.should eq %w{ bill nevermore }
      end

    end

    context :credentials_not_exist do

      before(:each) do
        File.should_receive(:exist?).with(subject::NCC_CREDENTIALS_FILE).and_return(false)
      end

      it 'should produce log message' do
        subject.credentials.should be_nil
      end

    end

  end

  describe '.extract_credentials' do

    it 'should return nils touple if there more than two elements' do
      subject.send(:extract_credentials, [1, 2, 3]).should be_nil
    end

    it 'should extract proper parts from credentials lines' do
      subject.send(:extract_credentials, %w{ username=john password=secret }).should eq %w{ john secret }
    end

    it 'should extract proper parts from credentials lines with reverse order' do
      subject.send(:extract_credentials, %w{ password=secret  username=john }).should eq %w{ john secret }
    end

  end

  describe '.divide_credential_tuple' do
    it 'takes part of a string after equal sign' do
      subject.send(:divide_credential_tuple, 'username=1234').should eq '1234'
      subject.send(:divide_credential_tuple, 'user=name=1234').should eq '1234'
    end
  end

  describe '.add_service' do

    before(:each) do
      SUSE::Connect::Zypper.stub(:write_credentials_file)
    end

    let :mock_service do
      sources = { 'name' => 'url', 'lastname' => 'furl' }
      SUSE::Connect::Service.new(
          :sources   => sources,
          :enabled   => %w{ fehu uruz ansuz },
          :norefresh => %w{ green coffee loki }
      )
    end

    it 'removes old service' do
      SUSE::Connect::Zypper.should_receive(:remove_service).with('name')
      SUSE::Connect::Zypper.should_receive(:remove_service).with('lastname')
      subject.add_service mock_service
    end

    it 'add each service from set' do
      SUSE::Connect::Zypper.should_receive(:add_service).with('name', 'url')
      SUSE::Connect::Zypper.should_receive(:add_service).with('lastname', 'furl')
      subject.add_service mock_service
    end

    it 'enables all repos for this service' do
      SUSE::Connect::Zypper.should_receive(:enable_service_repository).with('name', 'fehu')
      SUSE::Connect::Zypper.should_receive(:enable_service_repository).with('name', 'uruz')
      SUSE::Connect::Zypper.should_receive(:enable_service_repository).with('name', 'ansuz')

      SUSE::Connect::Zypper.should_receive(:enable_service_repository).with('lastname', 'fehu')
      SUSE::Connect::Zypper.should_receive(:enable_service_repository).with('lastname', 'uruz')
      SUSE::Connect::Zypper.should_receive(:enable_service_repository).with('lastname', 'ansuz')

      subject.add_service mock_service
    end

    it 'enables service repository for each of enabled' do

      SUSE::Connect::Zypper.should_receive(:add_service).with('name', 'url')
      SUSE::Connect::Zypper.should_receive(:add_service).with('lastname', 'furl')

      subject.add_service mock_service
    end

    it 'writes credentials file in corresponding file in credentials.d' do
      SUSE::Connect::Zypper.should_receive(:write_source_credentials).with('name')
      SUSE::Connect::Zypper.should_receive(:write_source_credentials).with('lastname')
      subject.add_service mock_service
    end

    it 'raise if non-Service object passed' do
      expect { subject.add_service('setup') }.to raise_error ArgumentError, 'only Service accepted'
    end

    it 'refresh services' do
      SUSE::Connect::Zypper.should_receive(:refresh).exactly(1).times
      subject.add_service mock_service
    end

    it 'set provided repo names to norefresh for each service' do

      SUSE::Connect::Zypper.should_receive(:disable_repository_autorefresh).with('name', 'green')
      SUSE::Connect::Zypper.should_receive(:disable_repository_autorefresh).with('name', 'coffee')
      SUSE::Connect::Zypper.should_receive(:disable_repository_autorefresh).with('name', 'loki')

      SUSE::Connect::Zypper.should_receive(:disable_repository_autorefresh).with('lastname', 'green')
      SUSE::Connect::Zypper.should_receive(:disable_repository_autorefresh).with('lastname', 'coffee')
      SUSE::Connect::Zypper.should_receive(:disable_repository_autorefresh).with('lastname', 'loki')

      subject.add_service mock_service
    end

  end

end
