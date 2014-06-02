require 'yaml'

module SUSE
  module Connect

    # Class for handling SUSEConnect configuration
    class Config

      DEFAULT_CONFIG_FILE = '/etc/SUSEConnect'

      class << self
        attr_accessor :attributes, :serializable

        def attribute_accessors(*attributes)
          self.attributes = attributes
          attr_accessor(*(attributes))
        end

        def serializable_attributes(*attributes)
          self.serializable = attributes
        end
      end

      attribute_accessors :url, :regcode, :language, :insecure

      serializable_attributes :url, :insecure

      def initialize(file = DEFAULT_CONFIG_FILE)
        @file = file

        read.keys.each do |key|
          if self.class.attributes.include?(key.to_sym)
            instance_variable_set("@#{key}", read[key])
          end
        end
      end

      def read
        if File.exist?(@file)
          @settings ||= (YAML.load_file(@file) || {})
        else
          {}
        end
      end

      def write
        !File.write(@file, to_yml).zero?
      end

      def to_yml
        YAML.dump(to_hash)
      end

      def to_hash
        hash = {}
        instance_variables.each do |variable|
          key = variable.to_s.gsub('@', '')
          hash[key] = instance_variable_get variable if self.class.attributes.include?(key.to_sym)
        end
        hash
      end

    end
  end
end
