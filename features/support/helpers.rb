def service_name
  product = SUSE::Connect::Zypper.base_product
  if product.identifier == 'openSUSE'
    "#{product.identifier}_#{product.version}_#{product.arch}"
  else
    identifier = product.instance_variable_get(:@summary).tr(' ', '_')
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

def regcode_for_test(regcode_kind)
  # Special case: shortcircuit all invalid
  return 'INVALID_REGCODE' if regcode_kind == 'INVALID' || regcode_kind.nil?

  regcode_key = case regcode_kind
                when 'VALID'
                  'VALID_REGCODE'
                when 'EXPIRED'
                  'EXPIRED_REGCODE'
                when 'NOTYETACTIVATED'
                  'NOT_ACTIVATED_REGCODE'
                end

  ENV.fetch(regcode_key)
end
