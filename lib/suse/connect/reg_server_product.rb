# Product received from SCC
class SUSE::Connect::RegServerProduct < SUSE::Connect::ServerDrivenModel

  include SUSE::Connect::ComparableProduct

  def initialize(*args)
    super
    self.class.send(:alias_method, :product_ident, :zypper_name) if self.respond_to?(:zypper_name)
    self.class.send(:alias_method, :version, :zypper_version) if self.respond_to?(:zypper_version)
  end

end
