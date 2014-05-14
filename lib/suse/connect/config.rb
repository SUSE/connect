# require 'fileutils'
require 'yaml'

module SUSE
  module Connect

    # Class for handling SUSEConnect configuration
    class Config
      DEFAULT_CONFIG_FILE = '/etc/SUSEConnect.yml'

      class << self
        attr_accessor :attributes

        def attribute_accessors(*attributes)
          self.attributes = attributes
          attr_accessor(*(attributes))
        end
      end

      attribute_accessors :url, :regcode, :language

      def initialize(file = DEFAULT_CONFIG_FILE)
        @file = file

        self.read.keys.each do |key|
          if self.class.attributes.include?(key.to_sym)
            instance_variable_set("@#{key}", self.read[key])
          end
        end
      end

      def read
        if File.exist?(@file)
          @settings ||= YAML.load_file(@file)
        else
         {}
        end
      end

      def write
        !File.write(@file, self.to_yml).zero?
      end

      def to_yml
        YAML.dump(self.to_hash)
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
