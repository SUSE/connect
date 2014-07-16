require 'ostruct'

# Layer on top of registration server models
class SUSE::Connect::Remote::ServerDrivenModel < OpenStruct

  def initialize(json_response_hash)
    unless json_response_hash.kind_of?(Hash)
      raise ArgumentError, "#{self.class.name}: Only Hash instance accepted, got #{json_response_hash.class}"
    end
    super
  end

end
