require 'suse/connect/core_ext/hash_refinement'
using SUSE::Connect::CoreExt::HashRefinement

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
        attributes.each do |key, value|
          attributes[key] = value.map(&:to_h) if value.is_a?(Array) && value.any? {|v| v.is_a?(OpenStruct) }
        end
        attributes
      end
    end
  end
end
