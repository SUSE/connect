require 'spec_helper'

describe SUSE::Connect::Client do

  subject { SUSE::Connect::Client.new({}) }

  describe '.new' do

    context :empty_opts do

      it 'should set url to default_url' do
        subject.url.should eq subject.class::DEFAULT_URL
      end

    end

    context :passed_opts do

      subject { Client.new(:url => 'http://dummy:42') }

      let :parsed_uri do
        URI.parse(subject.url)
      end

      it 'should set port to one from options if it was passed via constructor' do
        parsed_uri.port.should eq 42
      end

      it 'should set host to one from options if it was passed via constructor' do
        parsed_uri.host.should eq 'dummy'
      end

    end

  end

  describe '#announce_system' do

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'login' => 'lg', 'password' => 'pw' })
      Api.any_instance.stub(:announce_system => api_response)
      subject.stub(:token_auth => true)
    end

    it 'writes credentials file' do
      Zypper.should_receive(:write_base_credentials).with('lg', 'pw')
      subject.stub(:api)
      subject.announce_system
    end

    it 'calls underlying api' do
      Zypper.stub(:write_base_credentials)
      Api.any_instance.should_receive(:announce_system)
      subject.announce_system
    end

  end

  describe '#activate_subscription' do

    before do
      api_response = double('api_response')
      api_response.stub(:body => { :sources => { :foo => 'bar' } })
      Api.any_instance.stub(:activate_subscription => api_response)
      System.stub(:credentials => %w{ meuser mepassword})
      Zypper.stub(:base_product => ({ :name => 'SLE_BASE' }))
      System.stub(:add_service)
      subject.stub(:basic_auth => 'secretsecret')
    end

    it 'selects base product' do
      Zypper.should_receive(:base_product).and_return(:name => 'SLE_BASE')
      subject.activate_subscription
    end

    it 'gets login and password from system' do
      subject.should_receive(:basic_auth)
      subject.activate_subscription
    end

    it 'calls underlying api with proper parameters' do
      Api.any_instance.should_receive(:activate_subscription)
        .with('secretsecret', Zypper.base_product)
      subject.activate_subscription
    end

    it 'adds a service' do
      System.should_receive(:add_service)
      subject.activate_subscription
    end

  end

  describe '#execute!' do

    before do
      Client.any_instance.stub(:announce_system)
      Client.any_instance.stub(:activate_subscription)
      Zypper.stub(:base_product => { :name => 'SLE_BASE' })
      Zypper.stub(:add_service => true)
      subject.class.any_instance.stub(:basic_auth => true)
      subject.class.any_instance.stub(:token_auth => true)
    end

    it 'should call announce if system not registered' do
      System.stub(:registered? => false)
      subject.should_receive(:announce_system)
      subject.execute!
    end

    it 'should not call announce on api if system registered' do

      System.stub(:registered? => true)
      subject.should_not_receive(:announce_system)
      subject.execute!
    end

    it 'should call activate_subscription on api' do
      System.stub(:registered? => true)
      subject.should_receive(:activate_subscription)
      subject.execute!
    end

  end

  describe '?token_auth' do

    it 'returns string for auth header' do
      Client.new(:token => 'lambada').send(:token_auth).should eq 'Token token=lambada'
    end

    it 'raise if no token passed, but method requested' do
      expect { Client.new({}).send(:token_auth) }
        .to raise_error CannotBuildTokenAuth, 'token auth requested, but no token provided'
    end

  end

  describe '?basic_auth' do

    it 'returns string for auth header' do
      System.stub(:credentials => %w{bob dylan})
      base64_line = "Basic #{Base64.encode64('bob:dylan')}"
      Client.new({}).send(:basic_auth).should eq base64_line
    end

    it 'raise if cannot get credentials' do
      expect { Client.new({}).send(:basic_auth) }
        .to raise_error CannotBuildBasicAuth, 'cannot get proper username and password'
    end

  end

end
