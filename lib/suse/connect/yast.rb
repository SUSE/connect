# YaST class provides methods emulating SCC's API.
class SUSE::Connect::YaST

  class << self

    attr_accessor :options

    # Announces the system to SCC (usually by taking a token / regcode).
    # Writes SCC / system credentials to the system and
    # additionally returns them for convenience.
    #
    # @param params [Hash] optional parameters:
    #  - token [String]
    #  - hostname [String]
    #  - email [String]
    #  - parent [String]
    #  - hwinfo [Hash]
    # == Returns:
    # SCC / system credentials [Hash]:
    #  - login [String]
    #  - password [String]
    def announce_system(params = {})
      Client.new(params).announce_system
    end

  end

end
