# Class is layer between server responds and inheriting classes E.g. RegServerSubscription
class SUSE::Connect::ServerDrivenModel

  def initialize(json_response_hash)

    raise ArgumentError, 'Only Hash instance accepted' unless json_response_hash.is_a?(Hash)

    json_response_hash.each_pair do |attr, val|
      self.class.send(:class_eval) do
        attr_accessor attr.to_sym
      end
      send("#{attr.to_sym}=", val)
    end
  end

end
