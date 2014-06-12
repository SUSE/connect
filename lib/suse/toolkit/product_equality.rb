# module used to check two products for equality
# works for both zypper and registration server originated products
module SUSE::Toolkit::ProductEquality

  def ==(other)

    return false unless other.is_a?(SUSE::Toolkit::ProductEquality)

    [:identifier, :version, :arch].all? do |attr|
      send(attr) == other.send(attr)
    end

  end

end
