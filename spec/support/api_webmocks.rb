require 'json'

def api_header_version
  "application/json,application/vnd.scc.suse.com.#{SUSE::Connect::Api::VERSION}+json"
end

def stub_announce_call
  response_body = JSON.parse(File.read('spec/fixtures/announce_response.json')).to_json
  stub_request(:post, 'https://example.com/connect/subscriptions/systems')
    .with(headers: { 'Authorization' => 'token', 'Content-Type' => 'application/json' })
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_activate_call
  response_body = JSON.parse(File.read('spec/fixtures/activate_response.json')).to_json
  headers       = { 'Authorization' => 'basic_auth_mock', 'Content-Type' => 'application/json' }
  request_body  = {
    identifier: 'SLES',
    version: '11-SP2',
    arch: 'x86_64',
    release_type: nil,
    token: 'token-shmocken',
    email: nil
  }
  stub_request(:post, 'https://example.com/connect/systems/products')
    .with(headers: headers, body: request_body)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_upgrade_call
  response_body = JSON.parse(File.read('spec/fixtures/upgrade_response.json')).to_json
  headers       = { 'Authorization' => 'basic_auth_mock', 'Content-Type' => 'application/json' }
  request_body  = {
    identifier: 'SLES',
    version: '12',
    arch: 'x86_64',
    release_type: nil
  }
  stub_request(:put, 'https://example.com/connect/systems/products')
    .with(headers: headers, body: request_body)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_products_call
  headers = { 'Content-Type' => 'application/json' }
  response_body = JSON.parse(File.read('spec/fixtures/products_response.json')).to_json
  stub_request(:get, 'https://example.com/connect/products')
    .with(headers: headers)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_show_product_call
  headers = { 'Content-Type' => 'application/json' }
  response_body = JSON.parse(File.read('spec/fixtures/show_product_response.json')).to_json
  stub_request(:get, 'https://example.com/connect/systems/products?arch=z42&identifier=rodent&release_type=foo&version=good')
    .with(headers: headers)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_deregister_call
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'Basic: encodedgibberish' }
  stub_request(:delete, 'https://example.com/connect/systems')
    .with(headers: headers)
    .to_return(status: 204, body: '', headers: {})
end

def stub_update_call
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'Basic: encodedgibberish' }
  stub_request(:put, 'https://example.com/connect/systems')
    .with(headers: headers)
    .to_return(status: 204, body: '', headers: {})
end

def stub_systems_services_call
  response_body = JSON.parse(File.read('spec/fixtures/systems_services_response.json')).to_json
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'basic_auth_string' }
  stub_request(:get, 'https://example.com/connect/systems/services')
    .with(headers: headers)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_systems_subscriptions_call
  response_body = JSON.parse(File.read('spec/fixtures/systems_subscriptions_response.json')).to_json
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'basic_auth_string' }
  stub_request(:get, 'https://example.com/connect/systems/subscriptions')
    .with(headers: headers)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_systems_activations_call
  response_body = JSON.parse(File.read('spec/fixtures/activations_response.json')).to_json
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'basic_auth_string' }
  stub_request(:get, 'https://example.com/connect/systems/activations')
    .with(headers: headers)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_system_migrations_call(kind, products)
  response_body = JSON.parse(File.read('spec/fixtures/migrations_response.json')).to_json
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'Basic: encodedgibberish' }
  products_data = products.map(&:to_h)
  products_data.each { |product| product.delete(:isbase) } # we do not send it to the server
  request_body = {
    installed_products: products_data
  }
  stub_request(:post, "https://example.com/connect/systems/products/#{(kind == :offline) ? 'offline_' : ''}migrations")
    .with(headers: headers, body: request_body.to_json)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_system_migrations_call_with_target_product(kind)
  response_body = JSON.parse(File.read('spec/fixtures/migrations_sle15_response.json')).to_json
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'Basic: encodedgibberish' }
  request_body = {
    installed_products: [
      { identifier: 'SLES', version: '12', arch: 'x86_64', release_type: nil }
    ],
    target_base_product: { identifier: 'SLES', version: '15.0', arch: 'x86_64', release_type: nil }
  }
  stub_request(:post, "https://example.com/connect/systems/products/#{(kind == :offline) ? 'offline_' : ''}migrations")
    .with(headers: headers, body: request_body.to_json)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_empty_system_migrations_call(kind)
  response_body = [].to_json
  headers = { 'Accept' => api_header_version, \
              'Authorization' => 'Basic: encodedgibberish' }
  request_body = {
    installed_products: [{ identifier: 'SLES', version: 'not-upgradeable', arch: 'x86_64', release_type: nil }]
  }
  stub_request(:post, "https://example.com/connect/systems/products/#{(kind == :offline) ? 'offline_' : ''}migrations")
    .with(headers: headers, body: request_body.to_json)
    .to_return(status: 200, body: response_body, headers: {})
end

def stub_list_installer_updates_call
  response_body = JSON.parse(File.read('spec/fixtures/list_installer_updates_response.json')).to_json
  headers = { 'Accept' => api_header_version }
  stub_request(:get, 'https://example.com/connect/repositories/installer?arch=x86_64&identifier=SLES&release_type&version=12.2')
    .with(headers: headers)
    .to_return(status: 200, body: response_body, headers: {})
end
