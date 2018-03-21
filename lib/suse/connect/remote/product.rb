require 'suse/toolkit/product_equality'
require 'suse/toolkit/cast'

# Product as sent from registration server
#
# Used by YaST already, do not refactor without consulting them!
# Reads attributes (i.e. calls #identifier, #version, #arch)
class SUSE::Connect::Remote::Product < SUSE::Connect::Remote::ServerDrivenModel
  include SUSE::Toolkit::ProductEquality
  include SUSE::Toolkit::Cast

  def initialize(product_hash)
    super
    # TODO: ensure we have array here
    self.extensions = extensions.map { |ext| self.class.new(ext) } if extensions
  end

  def to_params
    {
      identifier: identifier,
      version: version,
      arch: arch,
      release_type: release_type
    }
  end

  def to_triplet
    "#{identifier}/#{version}/#{arch}"
  end

  # This method is needed to compute the distro_target when /etc/products.d/baseproduct
  # does not exist. This happens e.g. when creating a rootfs from scratch.
  def distro_target
    version = self.version.scan(/\d+/)[0]
    identifier = self.identifier.downcase
    identifier = 'sle' if (identifier =~ /^sle/)
    "#{identifier}-#{version}-#{arch}"
  end
end
