require 'suse/toolkit/cast'

module SUSE
  module Connect
    # Product class is a common class to represent all products
    class Product < OpenStruct
      include SUSE::Toolkit::Cast

      def self.transform(old_product)
        product = Product.new
        product.identifier = old_product.identifier
        product.version = old_product.version
        product.arch = old_product.arch
        product.release_type = old_product.release_type
        product
      end
    end
  end
end
