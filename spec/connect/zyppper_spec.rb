require 'spec_helper'

describe SUSE::Connect::Zypper do

  before(:each) do
    Object.stub(:system => true)
  end

  subject { SUSE::Connect::Zypper }

  describe '.installed_products' do

    it 'returns valid list of products based on proper XML' do
      xml = File.read('spec/fixtures/products_valid.xml')
      Object.should_receive(:'`').with(include 'zypper').and_return(xml)
      subject.installed_products.first[:name].should eq 'SUSE_SLES'
    end

  end

  describe '.call' do

    it 'calls \'zypper\' with given parameters' do
      Object.should_receive(:system).with(include 'zypper services')
      subject.send(:call, 'services')
    end

    it 'logs failing commands' do
      Object.should_receive(:system).with(include 'nonexistinggibberish').and_return(false)
      SUSE::Connect::Logger.should_receive(:error).with('command `zypper nonexistinggibberish` failed')
      subject.send(:call, 'nonexistinggibberish')
    end

    it 'doesn\'t actually change anything on the system if OPTIONS[:drymode] is set'

  end

  describe '.add_service' do

    it 'calls zypper with proper arguments' do
      parameters = "--quiet --non-interactive addservice http://example.com 'branding'"
      Object.should_receive(:system).with(include parameters).and_return(true)
      subject.add_service('branding', 'http://example.com')
    end

  end

  describe '.remove_service' do

    it 'calls zypper with proper arguments' do
      parameters = "--quiet --non-interactive removeservice 'branding'"
      Object.should_receive(:system).with(include parameters).and_return(true)
      subject.remove_service('branding')
    end

  end

  describe '.refresh' do

    it 'calls zypper with proper arguments' do
      parameters = "refresh"
      Object.should_receive(:system).with(include parameters).and_return(true)
      subject.refresh
    end

  end


  describe '.enable_service_repository' do

    it 'calls zypper with proper arguments' do
      parameters = "--quiet modifyservice --ar-to-enable 'branding:tofu' 'branding'"
      Object.should_receive(:system).with(include parameters).and_return(true)
      subject.enable_service_repository('branding', 'tofu')
    end

  end

  describe '.disable_repository_autorefresh' do

    it 'calls zypper with proper arguments' do
      parameters = "--quiet modifyrepo --no-refresh 'branding:tofu'"
      Object.should_receive(:system).with(include parameters).and_return(true)
      subject.disable_repository_autorefresh('branding', 'tofu')
    end

  end

  describe '.write_credentials_file' do

    let :source_cred_file do
      opened_file = double('me_file')
      opened_file.stub(:puts => true)
      opened_file.stub(:close => true)
      opened_file
    end

    before(:each) do
      File.stub(:open => source_cred_file)
      File.any_instance.stub(:puts => true)
      Dir.stub(:mkdir => true)
      SUSE::Connect::System.stub(:credentials => %w{ dummy tummy })
    end


    it 'extracts username and password from system credentials' do
      SUSE::Connect::System.should_receive(:credentials)
      subject.write_credentials_file('name')
    end

    context :credentials_folder_exist do

      before(:each) do
        Dir.should_receive(:exists?).with(SUSE::Connect::System::ZYPPER_CREDENTIALS_DIR).and_return true
      end

      it 'will not create credentials.d folder' do
        Dir.should_not_receive(:mkdir).with(SUSE::Connect::System::ZYPPER_CREDENTIALS_DIR)
        subject.write_credentials_file('name')
      end

    end

    context :credentials_folder_not_exist do

      before(:each) do
        Dir.should_receive(:exists?).with(SUSE::Connect::System::ZYPPER_CREDENTIALS_DIR).and_return false
      end

      it 'creates credentials.d folder' do
        Dir.should_receive(:mkdir).with(SUSE::Connect::System::ZYPPER_CREDENTIALS_DIR)
        subject.write_credentials_file('name')
      end

    end

    it 'opens a file for writing with name of source suffixed by _credentials' do
      File.should_receive(:open).with('/etc/zypp/credentials.d/name_credentials', 'w')
      subject.write_credentials_file('name')
    end

    it 'writes a file with corresponding product credentials' do
      source_cred_file.should_receive(:puts).with('username=SCC_dummy')
      source_cred_file.should_receive(:puts).with('password=tummy')
      subject.write_credentials_file('name')
    end

    it 'closes a file for credentials' do
      source_cred_file.should_receive(:close)
      subject.write_credentials_file('name')
    end

  end

  describe '?sccized_login' do

    it 'should prepend login with SCC_ unless it already there' do
      subject.send(:sccized_login, 'bender').should eq 'SCC_bender'
    end

    it 'should return login if in is prefixed with SCC' do
      subject.send(:sccized_login, 'SCC_kif').should eq 'SCC_kif'
    end

  end


end
