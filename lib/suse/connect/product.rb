# Product Extensions to give to YaST.
# TODO: Maybe we should get rid of this class?
class SUSE::Connect::Product # rubocop:disable Documentation

  attr_reader :short_name, :long_name, :description, :product_ident, :version, :arch, :free, :eula_url

  # Constructor
  def initialize(product)
    @short_name    = product['name']
    @long_name     = product['long_name']
    @description   = product['description']
    @product_ident = product['zypper_name']
    @version = product['zypper_version']
    @arch = product['arch']
    @free = product['free']
    @eula_url = product['eula_url']
  end

end
