def service_name
  product = SUSE::Connect::Zypper.base_product
  if product.identifier == 'openSUSE'
    @service_name ||= "#{product.identifier}_#{product.version}_#{product.arch}"
  else
    identifier = product.instance_variable_get(:@summary).gsub(' ', '_')
    @service_name ||= "#{identifier}_#{product.arch}"
  end
end

def base_product_version
  # base_product_version will fail if libzypp is locked for testing
  # so use env vars if available
  {
    'SLE_12' => '12',
    'SLES_12' => '12',
    'SLE_12_SP1' => '12.1',
    'SLE_12_SP2' => '12.2',
    'SLE_12_SP3' => '12.3',
    'SLE_15' => '15'
  }.fetch(ENV['PRODUCT']) { SUSE::Connect::Zypper.base_product.version }
end

# rubocop:disable CyclomaticComplexity
# This is ugly logic, but it is this way for compatibility with the existing code
# If the TODOs are resolved, it can become simpler.
def regcode_for_test(regcode_kind)
  # Special case 1; shortcircuit all invalid
  return 'INVALID_REGCODE' if regcode_kind == 'INVALID' || regcode_kind.nil?

  # Special case 2; regcode in environment for valid
  return ENV['REGCODE'] if ENV['REGCODE'] && regcode_kind == 'VALID'

  test_regcodes = YAML.load_file('/root/.regcode')

  regcode_key = case regcode_kind
                when 'VALID'
                  'code'
                when 'EXPIRED'
                  'expired_code'
                when 'NOTYETACTIVATED'
                  'notyetactivated_code'
                end

  regcode_key.prepend('beta_') if base_product_version == '15'

  test_regcodes[regcode_key] || "regcode file does not contain '#{regcode_key}'!!"
end
# rubocop:enable CyclomaticComplexity
