# Extraction of dedicated class for Service representation
class SUSE::Connect::Remote::Service < SUSE::Connect::Remote::ServerDrivenModel

  def initialize(service_hash)
    super
    self.product = SUSE::Connect::Remote::Product.new(service_hash['product'])
  end

end
