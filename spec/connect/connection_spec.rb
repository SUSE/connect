require 'spec_helper'

describe SUSE::Connect::Connection do

  subject { SUSE::Connect::Connection }

  describe '.new' do

    let :secure_connection do
      subject.new('https://example.com')
    end

    it 'stores http object' do
      secure_connection.http.should be_kind_of Net::HTTP
    end

    it 'parse passed endpoint to http port and host' do
      secure_connection.http.port.should eq 443
      secure_connection.http.address.should eq 'example.com'
    end

    context :default_values do

      it 'set ssl to true by default' do
        secure_connection.http.use_ssl?.should be_true
      end

      it 'set insecure to false by default' do
        secure_connection.http.verify_mode.should eq OpenSSL::SSL::VERIFY_PEER
      end

    end

    context :passed_options do

      let :secure_connection do
        subject.new('https://example.com', :insecure => true)
      end

      it 'set ssl to true by default' do
        secure_connection.http.use_ssl?.should be_true
      end

      it 'set insecure to false by default' do
        secure_connection.http.verify_mode.should eq OpenSSL::SSL::VERIFY_NONE
      end

    end

  end

  describe '?json_request' do

    let :connection do
      subject.new('leg')
    end

    before do
      connection.http.should_receive(:request).and_return(OpenStruct.new(:body => 'bodyofostruct'))
      JSON.stub(:parse => { '1' => '2' })
    end

    context :get_request do

      it 'takes Net::HTTP::Get class to build request' do
        Net::HTTP::Get.should_receive(:new).and_call_original
        connection.send(:json_request, :get, '/api/v1/megusta')
      end

    end

    context :post_request do

      it 'takes Net::HTTP::Post class to build request' do
        Net::HTTP::Post.should_receive(:new).and_call_original
        connection.send(:json_request, :post, '/api/v1/megusta')
      end

    end

    context :put_request do

      it 'takes Net::HTTP::Put class to build request' do
        Net::HTTP::Put.should_receive(:new).and_call_original
        connection.send(:json_request, :put, '/api/v1/megusta')
      end

    end

    context :delete_request do

      it 'takes Net::HTTP::Delete class to build request' do
        Net::HTTP::Delete.should_receive(:new).and_call_original
        connection.send(:json_request, :delete, '/api/v1/megusta')
      end

    end

  end

  describe '#post' do

    let :connection do
      subject.new('https://example.com')
    end

    before do
      stub_request(:post, 'https://example.com/api/v1/test')
      .with(:body => '', :headers => { 'Authorization' => 'Token token=zulu'})
      .to_return(:status => 200, :body => '{}', :headers => {})
    end

    it 'hits requested endpoint with parametrized request' do
      result = connection.post('/api/v1/test', :auth => 'Token token=zulu')
      result.body.should eq({})
      result.code.should eq 200
    end

    it 'sends Accept-Language header with specified language' do
      stub_request(:post, 'https://example.com/api/v1/test')
      .with(:body => '', :headers => { 'Authorization' => 'Token token=zulu', 'Accept-Language' => 'blabla'})
      .to_return(:status => 200, :body => '{}', :headers => {})

      connection = subject.new('https://example.com', :language => 'blabla')
      result = connection.post('/api/v1/test', :auth => 'Token token=zulu')
    end

    it 'converts response into proper hash' do

      stub_request(:post, 'https://example.com/api/v1/test')
        .with(:body => '', :headers => { 'Authorization' => 'Token token=zulu' })
        .to_return(:status => 200, :body => "{\"keyyo\":\"vallue\"}", :headers => {})

      result = connection.post('/api/v1/test', :auth => 'Token token=zulu')
      result.body.should eq('keyyo' => 'vallue')
      result.code.should eq 200
    end

    it 'send params alongside with request' do

      stub_request(:post, 'https://example.com/api/v1/test')
        .with(:body => "{\"foo\":\"bar\",\"bar\":[1,3,4]}", :headers => { 'Authorization' => 'Token token=zulu' })
        .to_return(:status => 200, :body => "{\"keyyo\":\"vallue\"}", :headers => {})

      result = connection.post(
          '/api/v1/test',
          :auth => 'Token token=zulu',
          :params => { :foo => 'bar', :bar => [1, 3, 4] }
      )
      result.body.should eq('keyyo' => 'vallue')
      result.code.should eq 200
    end

    it 'raise an ApiError if response code anything but 200' do
      stub_request(:post, 'https://example.com/api/v1/test')
      .with(
          :body => '',
          :headers => { 'Authorization' => 'Token token=zulu' }
      )
      .to_return(
          :status => 422,
          :body => '{}'
      )

      expect do
        connection.post(
          '/api/v1/test',
          :auth   => 'Token token=zulu',
          :params => {}
        )
      end.to raise_error ApiError
    end

    it 'raise an error with response from api if response code anything but 200' do
      parsed_output = OpenStruct.new(
          :code => 422,
          :body => { 'error' => 'These are not the droids you were looking for' }
      )

      connection.should_receive(:json_request).and_return parsed_output
      expect { connection.post('/api/v1/test', :auth   => 'Token token=zulu', :params => {}) }
      .to raise_error(ApiError) do |error|
        error.code.should eq 422
        error.body.should eq('error' => 'These are not the droids you were looking for')
      end
    end
  end
end
