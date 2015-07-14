module SUSE
  module Toolkit
    # Object conversion
    module Cast
      def to_openstruct
        attributes = self.attributes
        attributes.each do |key, value|
          attributes[key] = value.map {|v| v.to_openstruct } if value.is_a?(Array) && value.any? {|v| v.is_a?(Hash) }
        end
        OpenStruct.new(attributes)
      end

      def attributes
        attributes = to_h
        attributes.each do |k, v|
          attributes[k] = v.map(&:to_h) if v.is_a?(Array) && v.any? {|v| v.is_a?(OpenStruct) }
        end
        attributes
      end
    end
  end
end

class Hash
  def to_openstruct
    OpenStruct.new self
  end
end
