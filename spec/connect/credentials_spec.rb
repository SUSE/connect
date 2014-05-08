require 'spec_helper'
require 'tmpdir'

describe SUSE::Connect::Credentials do

  let(:credentials_file) { SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE }

  describe '.read' do

    it 'creates Credentials object from a credentials file' do
      file = File.join(fixtures_dir, 'SCCcredentials')
      credentials = Credentials.read(file)
      expect(credentials.username).to eq 'SCC_f93f438773944ef087a30a37af7fc0a5'
      expect(credentials.password).to eq '231982b59ce961e38777c83685a5c42f'
      expect(credentials.file).to eq file
    end

    it 'raises an error when the file does not exist' do
      expect { Credentials.read('this_file_does_not_exist') }.to raise_error(MissingSccCredentialsFile)
    end

    it 'raises an error when username cannot be parsed' do
      File.stub(:exist?).and_return(true)
      File.stub(:read).with(credentials_file).and_return("me\nfe")
      expect { Credentials.read(credentials_file) }.to raise_error(
        MalformedSccCredentialsFile,
        'Cannot parse credentials file')
    end

    it 'raises an error when the password cannot be parsed' do
      File.stub(:exist?).with(credentials_file).and_return(true)
      File.stub(:read).with(credentials_file).and_return("username=me\nfe")
      expect { Credentials.read(credentials_file) }.to raise_error(
        MalformedSccCredentialsFile,
        'Cannot parse credentials file')
    end

  end

  describe '#write' do

    it 'creates a credentials file accessible only by user' do
      Dir.mktmpdir do |dir|
        credentials = Credentials.new('name', '1234', "#{dir}/SLES")
        expect { credentials.write }.not_to raise_error
        expect(File.size(credentials.file)).to be > 0
        expect(File.stat(credentials.file).mode).to eq 0100600
      end
    end

    it 'computes the filename to write in the --root case' do
      $root = '/path/to/root'
      credentials = Credentials.new('name', '1234', 'SLES')
      credentials.filename.should start_with '/path/to/root/'
      $root = nil
    end

    it 'raises an error when file name is not set' do
      credentials = Credentials.new('name', '1234', '')
      expect { credentials.write }.to raise_error(RuntimeError)
      credentials = Credentials.new('name', '1234', nil)
      expect { credentials.write }.to raise_error(RuntimeError)
    end

    it 'the written file can be read back' do
      Dir.mktmpdir do |dir|
        credentials = Credentials.new('name', '1234', "#{dir}/SLES_credentials")
        credentials.write
        read_credentials = Credentials.read(credentials.file)
        expect(read_credentials.username).to eq credentials.username
        expect(read_credentials.password).to eq credentials.password
        expect(read_credentials.file).to eq credentials.file
      end
    end
  end

  describe '#to_s' do

    it 'does not serialize password (to avoid logging it)' do
      user = 'USER'
      file = 'FOO_credentials'
      password = '*eiW0yie2*'
      credentials_str = Credentials.new(user, password, file).to_s
      expect(credentials_str).not_to include(password), 'The password is logged'
      expect(credentials_str).to include(user)
      expect(credentials_str).to include(file)
    end

  end

end
