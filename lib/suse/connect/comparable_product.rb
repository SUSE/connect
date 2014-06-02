module SUSE::Connect::ComparableProduct

  def ==(other_product)

    return false unless other_product.is_a?(SUSE::Connect::RegServerProduct) ||
        other_product.is_a?(SUSE::Connect::Product)

    [:product_ident, :version, :arch].all? do |attr|
      self.send(attr) == other_product.send(attr)
    end

  end

end
