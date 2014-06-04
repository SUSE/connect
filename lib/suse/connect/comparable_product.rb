# Shared mixin for zypper product and server product
module SUSE::Connect::ComparableProduct

  def ==(other)

    return false unless other.is_a?(SUSE::Connect::RegServerProduct) ||
        other.is_a?(SUSE::Connect::Product)

    [:product_ident, :version, :arch].all? do |attr|
      send(attr) == other.send(attr)
    end

  end

end
