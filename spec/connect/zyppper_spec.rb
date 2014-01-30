require 'spec_helper'

describe SUSE::Connect::Zypper do

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


end
