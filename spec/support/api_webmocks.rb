require 'json'

def stub_announce_call
  response_body = JSON.parse(File.read('spec/fixtures/announce_response.json')).to_json
  stub_request(:post, 'https://example.com/connect/subscriptions/systems').
      with(:headers => {'Authorization'=>'token', 'Content-Type'=>'application/json'}).
      to_return(:status => 200, :body => response_body, :headers => {})
end

def stub_activate_call
  response_body = JSON.parse(File.read('spec/fixtures/activate_response.json')).to_json
  headers       = { 'Authorization' => 'basic_auth_mock', 'Content-Type' => 'application/json' }
  request_body  = { :product_ident => 'SLES', :product_version => '11-SP2', :arch => 'x86_64',:token => 'token-shmocken' }
  stub_request(:post, 'https://example.com/connect/systems/products').
      with(:headers => headers, :body => request_body).
      to_return(:status => 200, :body => response_body, :headers => {})
end
