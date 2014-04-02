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

    subject { SUSE::Connect::Client.new(:token => 'blabla') }

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'login' => 'lg', 'password' => 'pw' })
      Api.any_instance.stub(:announce_system => api_response)
      subject.stub(:token_auth => true)
    end

    it 'calls underlying api' do
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

    it 'selects product' do
      Zypper.should_receive(:base_product).and_return(:name => 'SLE_BASE')
      subject.activate_subscription(Zypper.base_product)
    end

    it 'gets login and password from system' do
      subject.should_receive(:basic_auth)
      subject.activate_subscription(Zypper.base_product)
    end

    it 'calls underlying api with proper parameters' do
      Api.any_instance.should_receive(:activate_subscription)
        .with('secretsecret', Zypper.base_product)
      subject.activate_subscription(Zypper.base_product)
    end

  end

  describe '#execute!' do

    before do
      Zypper.stub(:base_product => { :name => 'SLE_BASE' })
      System.stub(:add_service => true)
      Zypper.stub(:write_base_credentials)
      subject.stub(:activate_subscription)
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

    it 'writes credentials file' do
      System.stub(:registered? => false)
      subject.stub(:announce_system => %w{ lg pw })
      Zypper.should_receive(:write_base_credentials).with('lg', 'pw')
      subject.execute!
    end

    it 'adds service after product activation' do
      System.stub(:registered? => true)
      System.should_receive(:add_service)
      subject.execute!
    end

  end

  describe '#products_for' do

    let(:stubbed_response) do
      OpenStruct.new(
        :code => 200,
        :body => [{ 'name' => 'short_name', 'zypper_name' => 'zypper_name' }],
        :success => true
      )
    end

    before do
      subject.stub(:basic_auth => 'Basic: encodedstring')
    end

    it 'collects data from api response' do
      subject.api.should_receive(:addons).with('Basic: encodedstring', 'SLES').and_return stubbed_response
      subject.products_for('SLES')
    end

    it 'returns array of extension products returned from api' do
      subject.api.should_receive(:addons).with('Basic: encodedstring', 'SLES').and_return stubbed_response
      pp subject.products_for('SLES').first.should be_kind_of Yast::Extension
    end

  end

end
