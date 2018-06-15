require 'ostruct'

# Layer on top of registration server models
class SUSE::Connect::Remote::ServerDrivenModel < OpenStruct
  attr_reader :client

  def initialize(client, json_response_hash)
    unless json_response_hash.is_a?(Hash)
      raise ArgumentError, "#{self.class.name}: Only Hash instance accepted, got #{json_response_hash.class}"
    end
    @client = client
    super(json_response_hash)
  end
end
