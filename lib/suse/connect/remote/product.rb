require 'suse/toolkit/product_equality'

# Product as sent from registration server
class SUSE::Connect::Remote::Product < SUSE::Connect::Remote::ServerDrivenModel

  include SUSE::Toolkit::ProductEquality

  def initialize(product_hash)
    super
    # TODO: ensure we have array here
    self.extensions = extensions.map {|ext| self.class.new(ext) } if extensions.is_a? Array
  end

end
