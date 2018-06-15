# Activation as sent from registration server
class SUSE::Connect::Remote::Activation < SUSE::Connect::Remote::ServerDrivenModel
  def initialize(client, activation_hash)
    super(client, activation_hash)
    self.service = SUSE::Connect::Remote::Service.new(client, activation_hash['service'])
  end
end
