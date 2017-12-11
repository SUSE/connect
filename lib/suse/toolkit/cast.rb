require 'suse/connect/core_ext/hash_refinement'
using SUSE::Connect::CoreExt::HashRefinement

module SUSE
  module Toolkit
    # Object conversion
    module Cast
      def to_openstruct
        attributes = self.attributes
        attributes.each do |key, value|
          attributes[key] = value.map { |v| v.to_openstruct } if value.is_a?(Array) && value.any? { |v| v.is_a?(Hash) }
        end
        OpenStruct.new(attributes)
      end

      def attributes
        attributes = to_h
        attributes.each do |key, value|
          attributes[key] = value.map(&:to_h) if value.is_a?(Array) && value.any? { |v| v.is_a?(OpenStruct) }
        end
        attributes
      end
    end
  end
end

# INFO: We have to convert OpenStruct instance to hash in order to be able to send it's attributes as a parameters
# https://github.com/SUSE/connect/blob/master/lib/suse/connect/api.rb#L97
# https://github.com/SUSE/connect/blob/master/lib/suse/connect/api.rb#L105
# https://github.com/SUSE/connect/blob/master/lib/suse/connect/api.rb#L161
class OpenStruct
  alias_method :to_params, :to_h
end
