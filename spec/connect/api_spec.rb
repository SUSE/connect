require 'spec_helper'

describe SUSE::Connect::Api do

  subject { SUSE::Connect::Api }

  let :client do
    client = double('client')
    client.stub(:url => 'https://example.com')
    client.stub(:options => {:token => 'token-shmocken'})
    client
  end

  describe '.new' do

    it 'require client object' do
      expect { subject.new() }.to raise_error ArgumentError
    end

    it 'require client object' do
      expect { subject.new(client) }.not_to raise_error
    end

  end

  describe 'announce_system' do

    before do
      stub_announce_call
      SUSE::Connect::Zypper.stub(:write_base_credentials => true)
    end

    mock_dry_file

    it 'sends a call with token to api' do
      SUSE::Connect::Connection.any_instance.should_receive(:post).and_call_original
      subject.new(client).announce_system('token')
    end

  end

  describe 'activate_subscription' do

    before do
      stub_activate_call
    end

    it 'sends a call with basic auth and params to api' do
      product = {:name => 'SLES', :version => '11-SP2', :arch => 'x86_64', :token => 'token-shmocken'}
      expected_payload = { :product_ident => 'SLES', :product_version => '11-SP2', :arch => 'x86_64', :token => 'token-shmocken' }
      SUSE::Connect::Connection.any_instance.should_receive(:post).with('/connect/systems/products', {:auth => 'basic_auth_mock', :params => expected_payload}).and_call_original
      subject.new(client).activate_subscription('basic_auth_mock', product)
    end

  end


end
