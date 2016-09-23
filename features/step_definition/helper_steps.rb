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
  SUSE::Connect::Zypper.base_product.version
end

def regcode_for_test(regcode_kind)
  # Special case 1; shortcircuit all invalid
  if regcode_kind == 'INVALID' || regcode_kind == nil
    return 'INVALID_REGCODE'
  end

  # Special case 2; regcode in environment for valid
  if ENV['REGCODE'] && regcode_kind == 'VALID'
    return ENV['REGCODE']
  end

  test_regcodes = YAML.load_file('/root/.regcode')

  regcode_key = case regcode_kind
                when 'VALID'
                  'code'
                when 'EXPIRED'
                  'expired_code'
                when 'NOTYETACTIVATED'
                  'notyetactivated_code'
                end

  regcode_key.prepend('beta_') if base_product_version == '12.2'

  test_regcodes[regcode_key] || "regcode file does not contain '#{regcode_key}'!!"
end

