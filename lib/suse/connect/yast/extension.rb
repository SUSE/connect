module SUSE
  module Connect
    module Yast
      # Yast Extension class
      class Extension

        attr_reader :short_name, :long_name, :description, :product_ident

        # Constructor
        def initialize(short_name, long_name, description, product_ident)
          @short_name    = short_name
          @long_name     = long_name
          @description   = description
          @product_ident = product_ident
        end

      end
    end
  end
end
