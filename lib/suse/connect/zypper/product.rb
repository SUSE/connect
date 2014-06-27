# Product Extensions to give to YaST.
class SUSE::Connect::Zypper::Product

  include SUSE::Toolkit::ProductEquality

  attr_reader :identifier, :version, :arch, :isbase, :release_type, :summary

  def initialize(product_hash)
    @product_hash  = product_hash
    @identifier    = @product_hash[:name]
    @version       = @product_hash[:version]
    @arch          = @product_hash[:arch]
    @isbase        = %w{1 true yes}.include?(@product_hash[:isbase])
    @release_type  = determined_release_type
    @summary       = @product_hash[:summary]
    @release       = @product_hash[:release]
  end

  private

  def determined_release_type

    oem_file = File.join(SUSE::Connect::Zypper::OEM_PATH, @product_hash[:productline] || '')

    if File.exist?(oem_file)
      line = File.readlines(oem_file).first
      return line.chomp if line
    end

    if @product_hash.key?(:registerrelease) && !@product_hash[:registerrelease].empty?
      return @product_hash[:registerrelease]
    end

    @product_hash[:flavor]

  end

end
