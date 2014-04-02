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
    subject { SUSE::Connect::Client.new({:token => "blabla"}) }

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'login' => 'lg', 'password' => 'pw' })
      Api.any_instance.stub(:announce_system => api_response)
      subject.stub(:token_auth => true)
    end

    #TODO push this into execute! test
    #it 'writes credentials file' do
    #  Zypper.should_receive(:write_base_credentials).with('lg', 'pw')
    #  subject.stub(:api)
    #  subject.execute!
    #end

    it 'calls underlying api' do
      #Zypper.stub(:write_base_credentials)
      Api.any_instance.should_receive(:announce_system)
      subject.announce_system
    end

  end

  describe '#activate_subscription' do

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'sources' => { :foo => 'bar' }, :enabled => true, :norefresh => false })
      Api.any_instance.stub(:activate_subscription => api_response)
      System.stub(:credentials => %w{ meuser mepassword})
      Zypper.stub(:base_product => ({ :name => 'SLE_BASE' }))
      System.stub(:add_service)
      subject.stub(:basic_auth => 'secretsecret')

    end

    #it 'selects product' do
    #  Zypper.should_receive(:base_product).and_return(:name => 'SLE_BASE')
    #  subject.activate_subscription(Zypper.base_product)
    #end

    it 'gets login and password from system' do
      subject.should_receive(:basic_auth)
      subject.activate_subscription(Zypper.base_product)
    end

    it 'calls underlying api with proper parameters' do
      Api.any_instance.should_receive(:activate_subscription)
        .with('secretsecret', Zypper.base_product)
      subject.activate_subscription(Zypper.base_product)
    end

    #it 'adds a service' do
    #  System.should_receive(:add_service)
    #  subject.activate_subscription(Zypper.base_product)
    #end

  end

  describe '#execute!' do

    before do
      # This is where the stubbing is wrong
      # I don't know why we would stub the methods that are being tested below
      # But this was already present
      #Client.any_instance.stub(:announce_system)
      #Client.any_instance.stub(:activate_subscription => Service.new( [Source.new("foo", "flub")], true, true))
      Zypper.stub(:base_product => { :name => 'SLE_BASE' })
      Zypper.stub(:add_service => true)
      Zypper.stub(:write_base_credentials)
      subject.class.any_instance.stub(:basic_auth => true)
      subject.class.any_instance.stub(:token_auth => true)
    end

    it 'should call announce if system not registered' do
      System.stub(:registered? => false)
      #System.stub(:add_service => true)
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
      subject.send(:token_auth, 'lambada').should eq 'Token token=lambada'
    end

    # I think this test can be deleted as we would now get ArgumentError if calling token_auth without args
    #it 'raise if no token passed, but method requested' do
    #  expect { subject.send(:token_auth, nil) }
    #    .to raise_error CannotBuildTokenAuth, 'token auth requested, but no token provided'
    #end

  end

  describe '?basic_auth' do

    it 'returns string for auth header' do
      System.stub(:credentials => %w{bob dylan})
      base64_line = 'Basic Ym9iOmR5bGFu'
      subject.send(:basic_auth).should eq base64_line
    end

    it 'raise if cannot get credentials' do
      System.stub(:credentials => nil)
      expect { subject.send(:basic_auth) }
        .to raise_error CannotBuildBasicAuth, 'cannot get proper username and password'
    end

  end

end
