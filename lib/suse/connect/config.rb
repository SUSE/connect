require 'yaml'

module SUSE
  module Connect

    # Class for handling SUSEConnect configuration
    class Config < Struct.new(:url, :regcode, :language, :insecure)

      DEFAULT_CONFIG_FILE = '/etc/SUSEConnect'

      def initialize(file = DEFAULT_CONFIG_FILE)
        @file = file

        read.each_pair do |key, value|
          if members.include?(key.to_sym)
            self[key] = value
          end
        end

        # default value if insecure is not specified
        self[:insecure] = false if self.insecure.nil?
      end

      def write
        File.write(@file, to_yaml)
      end

      def to_yaml
        # use own hash with keys instead of `to_h` as string as resulting yaml
        # looks better then with symbols
        YAML.dump(to_hash_with_string_keys)
      end

    private
      def to_hash_with_string_keys
        # OK, this code maybe look quite magic, but in fact it takes hash from
        # to_h and create new one with keys that is converted with to_s
        Hash[to_h.map {|k,v| [k.to_s, v] }]
      end

      def read
        return {} unless File.exists?(@file)

        YAML.load_file(@file) || {}
      end
    end
  end
end
