# Activation as sent from registration server
class SUSE::Connect::Remote::Activation < SUSE::Connect::Remote::ServerDrivenModel
  def initialize(activation_hash)
    super
    self.service = SUSE::Connect::Remote::Service.new(activation_hash['service'])
  end
end
