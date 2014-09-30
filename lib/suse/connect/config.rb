require 'yaml'

module SUSE
  module Connect

    # Class for handling SUSEConnect configuration
    class Config < Struct.new(:url, :regcode, :language, :insecure)

      DEFAULT_CONFIG_FILE = '/etc/SUSEConnect'

      class << self
        attr_accessor :serializable

        def serializable_attributes(*attributes)
          self.serializable = attributes
        end
      end

      serializable_attributes :url, :insecure

      def initialize(file = DEFAULT_CONFIG_FILE)
        @file = file

        read.each_pair do |key, value|
          self[key] = value if members.include?(key.to_sym)
        end

        # default value if insecure is not specified
        self[:insecure] = false if insecure.nil?
      end

      def merge!(overrides)
        self.class.serializable.each{|attr| self.send("#{attr}=", overrides[attr]) if overrides[attr] }
      end

      def write
        File.write(@file, to_yaml)
      end

      def to_yaml
        # use own hash with keys instead of `to_h` as string as resulting yaml
        # looks better then with symbols
        YAML.dump(select_serializable_attributes)
      end

      def select_serializable_attributes
        to_hash_with_string_keys.select {|key, value| self.class.serializable.include?(key.to_sym) }
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
