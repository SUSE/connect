# service
class SUSE::Connect::Source

  attr_reader :name, :url

  # Constructor
  # @param name [String] service name
  # @param url [URI, String] service URL
  def initialize(name, url)
    @name = name
    @url = url.is_a?(String) ? URI(url) : url
  end
end


