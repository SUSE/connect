# Extraction of dedicated class for Service representation
class SUSE::Connect::Remote::Service < SUSE::Connect::Remote::ServerDrivenModel
  def initialize(client, service_hash)
    super(client, service_hash)
    self.product = SUSE::Connect::Remote::Product.new(client, service_hash['product'])
  end
end
