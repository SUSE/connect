require 'spec_helper'

describe SUSE::Connect::System do

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
        subject.hwinfo.should eq({
                                     :cpu_type       => 'PowerPC 440',
                                     :cpu_count      => '250000',
                                     :platform_type  => 'x86_64',
                                     :hostname       => 'blue_gene',
                                     :virtualized    => false
                                 })

      end
    end

    context :virtualized do

      it 'should report that system is virtualized' do
        Object.should_receive(:'`').with('dmidecode').and_return "qemu\n"
        subject.hwinfo.should eq({
                                     :cpu_type       => 'PowerPC 440',
                                     :cpu_count      => '250000',
                                     :platform_type  => 'x86_64',
                                     :hostname       => 'blue_gene',
                                     :virtualized    => true
                                 })
      end

    end

  end

  describe '.read_credentials_file' do

    context :credentials_exist do

      before do
        File.should_receive(:exist?).with(subject::NCC_CREDENTIALS_FILE).and_return(true)
      end

      it 'should raise MalformedNccCredentialsFile if cannot parse lines' do
        File.any_instance.should_receive(:readlines).and_return(['me', 'fe'])
        expect { subject.read_credentials_file }
          .to raise_error SUSE::Connect::MalformedNccCredentialsFile, 'Cannot parse credentials file'
      end

      it 'should return username and password' do
        File.any_instance.should_receive(:readlines).and_return(['username=bill', 'password=nevermore'])
        subject.read_credentials_file.should eq %w{ bill nevermore }
      end

    end

    context :credentials_not_exist do

      before do
        File.should_receive(:exist?).with(subject::NCC_CREDENTIALS_FILE).and_return(false)
      end

      it 'should produce log message' do
        SUSE::Connect::Logger.should_receive(:error)
        subject.read_credentials_file
      end

    end

  end

  describe '.extract_credentials' do

    it 'should return nils touple if there more than two elements' do
      subject.send(:extract_credentials, [1,2,3]).should be_nil
    end

    it 'should extract proper parts from credentials lines' do
      subject.send(:extract_credentials, %w{ username=john password=secret }).should eq %w{ john secret }
    end

    it 'should extract proper parts from credentials lines with reverse order' do
      subject.send(:extract_credentials, %w{ password=secret  username=john }).should eq %w{ john secret }
    end

  end

  describe '.divide_credential_tuple' do
    it 'should take part of a string after equal sign' do
      subject.send(:divide_credential_tuple, 'username=1234').should eq '1234'
      subject.send(:divide_credential_tuple, 'user=name=1234').should eq '1234'
    end
  end

end
