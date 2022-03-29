require 'spec_helper'
require 'tmpdir'

describe SUSE::Connect::Credentials do
  let(:credentials_file) { SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE }

  describe '.system_credentials_file' do
    it 'without root folder set' do
      expect(Credentials.system_credentials_file).to eq Credentials::GLOBAL_CREDENTIALS_FILE
    end

    it 'with root folder set' do
      SUSE::Connect::System.filesystem_root = '/path/to/root'
      expected = File.join('/path/to/root', Credentials::GLOBAL_CREDENTIALS_FILE)
      expect(Credentials.system_credentials_file).to eq expected
      SUSE::Connect::System.filesystem_root = nil
    end
  end

  describe '.read' do
    it 'creates Credentials object from a credentials file' do
      file = File.join(fixtures_dir, 'SCCcredentials')
      credentials = Credentials.read(file)
      expect(credentials.username).to eq 'SCC_f93f438773944ef087a30a37af7fc0a5'
      expect(credentials.password).to eq '231982b59ce961e38777c83685a5c42f'
      expect(credentials.system_token).to be_nil
      expect(credentials.file).to eq file
    end

    it 'raises an error when the file does not exist' do
      expect { Credentials.read('this_file_does_not_exist') }.to raise_error(MissingSccCredentialsFile)
    end

    it 'raises an error when username cannot be parsed' do
      expect(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).with(credentials_file).and_return("me\nfe")
      expect { Credentials.read(credentials_file) }.to raise_error(MalformedSccCredentialsFile, 'Cannot parse credentials file')
    end

    it 'raises an error when the password cannot be parsed' do
      allow_any_instance_of(String).to receive(:match).with(/^\s*username\s*=\s*(\S+)\s*$/).and_return(true)
      allow_any_instance_of(String).to receive(:match).with(/^\s*password\s*=\s*(\S+)\s*$/).and_return(false)

      expect(File).to receive(:exist?).and_return(true)
      expect(File).to receive(:read).with(credentials_file).and_return("me\nfe")
      expect { Credentials.read(credentials_file) }.to raise_error(MalformedSccCredentialsFile, 'Cannot parse credentials file')
    end

    it 'does not raise an error when the system_token cannot be parsed' do
      allow_any_instance_of(String).to receive(:match).with(/^\s*username\s*=\s*(\S+)\s*$/).and_return(true)
      allow_any_instance_of(String).to receive(:match).with(/^\s*password\s*=\s*(\S+)\s*$/).and_return(true)
      allow_any_instance_of(String).to receive(:match).with(/^\s*system_token\s*=\s*(\S+)\s*$/).and_return(false)

      expect(File).to receive(:exist?).and_return(true)
      expect(File).to receive(:read).with(credentials_file).and_return("me\nfe")
      creds = nil
      expect { creds = Credentials.read(credentials_file) }.not_to raise_error

      expect(creds.system_token).to be_nil
    end
  end

  describe '#write' do
    it 'creates a credentials file accessible only by user' do
      Dir.mktmpdir do |dir|
        credentials = Credentials.new('name', '1234', nil, "#{dir}/SLES")
        expect { credentials.write }.not_to raise_error
        expect(File.size(credentials.file)).to be > 0
        expect(File.stat(credentials.file).mode).to eq 0100600
      end
    end

    it 'compute filename to write properly --root case' do
      SUSE::Connect::System.filesystem_root = '/path/to/root'
      credentials = Credentials.new('name', '1234', nil, 'SLES')
      expect(credentials.filename).to start_with '/path/to/root/'
      SUSE::Connect::System.filesystem_root = nil
    end

    it 'raises an error when file name is not set' do
      credentials = Credentials.new('name', '1234', nil, '')
      expect { credentials.write }.to raise_error(RuntimeError)
      credentials = Credentials.new('name', '1234', nil, nil)
      expect { credentials.write }.to raise_error(RuntimeError)
    end

    it 'the written file can be read back' do
      Dir.mktmpdir do |dir|
        credentials = Credentials.new('name', '1234', 'whatever', "#{dir}/SLES_credentials")
        credentials.write
        read_credentials = Credentials.read(credentials.file)
        expect(read_credentials.username).to eq credentials.username
        expect(read_credentials.password).to eq credentials.password
        expect(read_credentials.system_token).to eq credentials.system_token
        expect(read_credentials.file).to eq credentials.file
      end
    end
  end

  describe '#to_s' do
    it 'does not serialize password (to avoid logging it)' do
      user = 'USER'
      file = 'FOO_credentials'
      password = '*eiW0yie2*'
      token = 'whatever'
      credentials_str = Credentials.new(user, password, token, file).to_s
      expect(credentials_str).not_to include(password), 'The password is logged'
      expect(credentials_str).to include(user)
      expect(credentials_str).to include(token)
      expect(credentials_str).to include(file)
    end
  end

  describe '#to_h' do
    it 'returns a hash representation of the object' do
      hash = Credentials.new('USER', '*eiW0yie2*', 'whatever', 'FOO_credentials').to_h
      expect(hash.values).to include('USER')
      expect(hash.values).to include('*eiW0yie2*')
      expect(hash.values).to include('whatever')
      expect(hash.values).to include('FOO_credentials')
    end
  end
end
