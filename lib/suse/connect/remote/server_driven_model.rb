require 'ostruct'

# Layer on top of registration server models
class SUSE::Connect::Remote::ServerDrivenModel < OpenStruct

  def initialize(json_response_hash)
    raise ArgumentError, 'Only Hash instance accepted' unless json_response_hash.is_a?(Hash)
    super
  end

end
