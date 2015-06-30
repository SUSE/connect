require 'yaml'
require 'ostruct'

module SUSE
  module Connect

    # Class for handling SUSEConnect configuration
    #
    # Used by YaST already, do not refactor without consulting them!
    # Reading the config file (#url, #insecure), for writing it uses the yast.rb wrapper
    class Config < OpenStruct

      DEFAULT_CONFIG_FILE = '/etc/SUSEConnect'
      DEFAULT_URL = 'https://scc.suse.com'

      class << self
        attr_accessor :serializable

        def serializable_attributes(*attributes)
          self.serializable = attributes
        end
      end

      serializable_attributes :url, :insecure, :language

      def initialize(file = DEFAULT_CONFIG_FILE)
        @file = file
        super(read)
        self.insecure ||= false
        self.url ||= DEFAULT_URL
      end

      def write!
        File.write(@file, to_yaml)
      end

      def to_yaml
        # use own hash with keys instead of `to_h` as string as resulting yaml
        # looks better then with symbols
        YAML.dump(select_serializable_attributes)
      end

      def select_serializable_attributes
        to_hash_with_string_keys.select {|key, _| self.class.serializable.include?(key.to_sym) }
      end

      # allows to merge hash from other source into config to maintain precedence
      def merge!(overwrites)
        raise ArgumentError, 'Only Hash instance can be merged' unless overwrites.is_a?(Hash)
        overwrites.each_pair do |name, value|
          self[name] = value if value
        end
        self
      end

      def url_default?
        url == DEFAULT_URL
      end

      private

      def to_hash_with_string_keys
        # OK, this code maybe look quite magic, but in fact it takes hash from
        # to_h and create new one with keys that is converted with to_s
        Hash[to_h.map {|k, v| [k.to_s, v] }]
      end

      def read
        return {} unless File.exist?(@file)
        YAML.load_file(@file) || {}
      end
    end
  end
end
