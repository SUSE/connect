def service_name
  product = SUSE::Connect::Zypper.base_product
  if product.identifier == 'openSUSE'
    "#{product.identifier}_#{product.version}_#{product.arch}"
  else
    identifier = product.instance_variable_get(:@summary).gsub(' ', '_')
    "#{identifier}_#{product.arch}"
  end
end

def base_product_version
  sp = ENV.fetch('PRODUCT').split('_', 2).last
  version_to_dot_notation(sp)
end

# ('12') => '12'
# ('12.0', '_') => '12_SP0'
# ('12.1', '_') => '12_SP1'
# ('12.1', '-') => '12-SP1'
def version_to_sp_notation(dot_notation, separator)
  dot_notation.split('.').join("#{separator}SP")
end

# ('12') => '12'
# ('12_SP0') => '12.0'
# ('12_SP1') => '12.1'
# ('12-SP1') => '12.1'
def version_to_dot_notation(sp_notation)
  sp_notation.gsub(/_SP|-SP/, '.')
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
