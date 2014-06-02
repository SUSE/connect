# Product Extensions to give to YaST.
class SUSE::Connect::Product # rubocop:disable Documentation

  include SUSE::Connect::ComparableProduct

  attr_reader :id, :short_name, :long_name, :description, :product_ident, :version, :arch, :free, :eula_url, :extensions

  # Constructor
  def initialize(product)

    @short_name    = product['name']
    @long_name     = product['long_name']
    @description   = product['description']
    @product_ident = product['zypper_name']
    @extensions    = product['extensions'].map {|e| SUSE::Connect::Product.new(e) } if product['extensions']
    @version       = product['zypper_version']
    @arch          = product['arch']
    @free          = product['free']
    @eula_url      = product['eula_url']
    @release_type  = product['release_type']
    @id            = product['id']
  end

end
