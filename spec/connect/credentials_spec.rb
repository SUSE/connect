require 'spec_helper'
require 'tmpdir'

describe SUSE::Connect::Credentials do
  describe '.read' do
    it 'creates Credentials object from a credentials file' do
      file = File.join(fixtures_dir, 'SCCcredentials')
      credentials = SUSE::Connect::Credentials.read(file)
      expect(credentials.username).to eq 'SCC_f93f438773944ef087a30a37af7fc0a5'
      expect(credentials.password).to eq '231982b59ce961e38777c83685a5c42f'
      expect(credentials.file).to eq file
    end

    it 'raises an error when the file does not exist' do
      expect { SUSE::Connect::Credentials.read('this_file_does_not_exist') }.to raise_error(MissingSccCredentialsFile)
    end

    it 'raises an error when username cannot be parsed' do
      File.stub(:exist?).with(CREDENTIALS_FILE).and_return(true)
      File.stub(:read).with(CREDENTIALS_FILE).and_return("me\nfe")
      expect { SUSE::Connect::Credentials.read(CREDENTIALS_FILE) }.to raise_error(
        MalformedSccCredentialsFile,
        'Cannot parse credentials file')
    end

    it 'raises an error when the password cannot be parsed' do
      File.stub(:exist?).with(CREDENTIALS_FILE).and_return(true)
      File.stub(:read).with(CREDENTIALS_FILE).and_return("username=me\nfe")
      expect { SUSE::Connect::Credentials.read(CREDENTIALS_FILE) }.to raise_error(
        MalformedSccCredentialsFile,
        'Cannot parse credentials file')
    end
  end

  describe '#write' do
    it 'creates a credentials file accessible only by user' do
      # use a tmpdir for writing the file
      Dir.mktmpdir do |dir|
        credentials = SUSE::Connect::Credentials.new('name', '1234', "#{dir}/SLES")
        expect { credentials.write }.not_to raise_error

        # the file is not empty
        expect(File.size(credentials.file)).to be > 0
        # standard file with "rw-------" permissions
        expect(File.stat(credentials.file).mode).to eq 0100600
      end
    end

    it 'raises an error when file name is not set' do
      credentials = SUSE::Connect::Credentials.new('name', '1234', '')
      expect { credentials.write }.to raise_error(RuntimeError)
      credentials = SUSE::Connect::Credentials.new('name', '1234', nil)
      expect { credentials.write }.to raise_error(RuntimeError)
    end

    it 'the written file can be read back' do

      # use a tmpdir for writing the file
      Dir.mktmpdir do |dir|
        credentials = SUSE::Connect::Credentials.new('name', '1234', "#{dir}/SLES_credentials")
        credentials.write
        read_credentials = SUSE::Connect::Credentials.read(credentials.file)

        # the read credentials are exactly the same as written
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
      credentials_str = SUSE::Connect::Credentials.new(user, password, file).to_s
      expect(credentials_str).not_to include(password), 'The password is logged'
      expect(credentials_str).to include(user)
      expect(credentials_str).to include(file)
    end
  end

end
