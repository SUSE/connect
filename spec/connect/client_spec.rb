require 'spec_helper'

describe SUSE::Connect::Client do

  subject { SUSE::Connect::Client.new({}) }

  describe '.new' do

    context :empty_opts do

      it 'should set port to default if it was not passed via constructor' do
        subject.options[:port].should eq subject.class::DEFAULT_PORT
      end

      it 'should set host to default if it was not passed via constructor' do
        subject.options[:host].should eq subject.class::DEFAULT_HOST
      end

      it 'should build url with default host and port' do
        subject.url.should eq "https://#{subject.class::DEFAULT_HOST}"
      end

    end

    context :passed_opts do

      subject { SUSE::Connect::Client.new({ :host => 'dummy', :port => '42' }) }

      it 'should set port to one from options if it was passed via constructor' do
        subject.options[:port].should eq '42'
      end

      it 'should set host to one from options if it was passed via constructor' do
        subject.options[:host].should eq 'dummy'
      end

      context :secure_requested do

        subject { SUSE::Connect::Client.new({ :host => 'dummy', :port => '443' }) }

        it 'should build url with https schema if passed 443 port' do
          subject.url.should eq 'https://dummy'
        end

      end

    end


  end

  describe '#announce_system' do

    before do
      api_response = double('api_response')
      api_response.stub(:body => {'login' => 'lg', 'password' => 'pw'})
      SUSE::Connect::Api.any_instance.stub(:announce_system => api_response)
      subject.stub(:token_auth => true)
    end

    it 'writes credentials file' do
      SUSE::Connect::Zypper.should_receive(:write_base_credentials).with('lg', 'pw')
      subject.stub(:api)
      subject.announce_system
    end

    it 'calls underlying api' do
      SUSE::Connect::Zypper.stub(:write_base_credentials)
      SUSE::Connect::Api.any_instance.should_receive(:announce_system)
      subject.announce_system
    end

  end

  describe '#activate_subscription' do

    before do
      api_response = double('api_response')
      api_response.stub(:body => {:sources => {:foo => 'bar'}})
      SUSE::Connect::Api.any_instance.stub(:activate_subscription => api_response)
      SUSE::Connect::System.stub(:credentials => ['meuser', 'mepassword'])
      SUSE::Connect::Zypper.stub(:base_product => ({:name => 'SLE_BASE'}))
      SUSE::Connect::System.stub(:add_service)
      subject.stub(:basic_auth => 'secretsecret')
    end

    it 'selects base product' do
      SUSE::Connect::Zypper.should_receive(:base_product).and_return({:name => 'SLE_BASE'})
      subject.activate_subscription
    end

    it 'gets login and password from system' do
      subject.should_receive(:basic_auth)
      subject.activate_subscription
    end

    it 'calls underlying api with proper parameters' do
      SUSE::Connect::Api.any_instance.should_receive(:activate_subscription).
          with('secretsecret', SUSE::Connect::Zypper.base_product)

      subject.activate_subscription
    end

    it 'adds a service' do
      SUSE::Connect::System.should_receive(:add_service)
      subject.activate_subscription
    end

  end

  describe '#execute!' do

    before do
      SUSE::Connect::Client.any_instance.stub(:announce_system)
      SUSE::Connect::Client.any_instance.stub(:activate_subscription)
      SUSE::Connect::Zypper.stub(:base_product => {:name => 'SLE_BASE'})
      SUSE::Connect::Zypper.stub(:add_service => true)
      subject.class.any_instance.stub(:basic_auth => true)
      subject.class.any_instance.stub(:token_auth => true)
    end

    it 'should call announce if system not registered' do
      SUSE::Connect::System.stub(:registered? => false)
      subject.should_receive(:announce_system)
      subject.execute!
    end

    it 'should not call announce on api if system registered' do

      SUSE::Connect::System.stub(:registered? => true)
      subject.should_not_receive(:announce_system)
      subject.execute!
    end

    it 'should call activate_subscription on api' do
      SUSE::Connect::System.stub(:registered? => true)
      subject.should_receive(:activate_subscription)
      subject.execute!
    end

  end

  describe '?token_auth' do

    it 'returns string for auth header' do
      SUSE::Connect::Client.new({:token => 'lambada'}).send(:token_auth).should eq 'Token token=lambada'
    end

    it 'raise if no token passed, but method requested' do
      expect { SUSE::Connect::Client.new({}).send(:token_auth) }.
          to raise_error SUSE::Connect::CannotBuildTokenAuth, 'token auth requested, but no token provided'
    end

  end

  describe '?basic_auth' do

    it 'returns string for auth header' do
      SUSE::Connect::System.stub(:credentials => ['bob', 'dylan'])
      base64_line = "Basic #{Base64::encode64('bob:dylan')}"
      SUSE::Connect::Client.new({}).send(:basic_auth).should eq base64_line
    end

    it 'raise if cannot get credentials' do
      expect {SUSE::Connect::Client.new({}).send(:basic_auth) }.
          to raise_error SUSE::Connect::CannotBuildBasicAuth, 'cannot get proper username and password'
    end

  end

end
