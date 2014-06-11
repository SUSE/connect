# module used to check two products for equality
# works for both zypper and registration server originated products
module SUSE::Toolkit::ProductEquality

  def ==(other)

    return false unless other.is_a?(SUSE::Connect::Remote::Product) ||
        other.is_a?(SUSE::Connect::Zypper::Product)

    [:identifier, :version, :arch].all? do |attr|
      send(attr) == other.send(attr)
    end

  end

end
