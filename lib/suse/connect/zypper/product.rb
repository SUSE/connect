# Product Extensions to give to YaST.
class SUSE::Connect::Zypper::Product

  include SUSE::Toolkit::ProductEquality

  attr_reader :identifier, :version, :arch, :isbase, :release_type

  def initialize(product_hash)
    @product_hash  = product_hash
    @identifier    = @product_hash[:name]
    @version       = @product_hash[:version]
    @arch          = @product_hash[:arch]
    @isbase        = %w{1 true yes}.include?(@product_hash[:isbase])
    @release_type  = determined_release_type
  end

  private

  def determined_release_type

    release_type = @product_hash[:flavor]

    if @product_hash.key?(:registerrelease) && !@product_hash[:registerrelease].empty?
      release_type = @product_hash[:registerrelease]
    end

    oem_file = File.join(SUSE::Connect::Zypper::OEM_PATH, @product_hash[:productline] || '')

    if File.exist?(oem_file)
      line = File.readlines(oem_file).first
      release_type = line.chomp if line
    end
    release_type
  end

end
