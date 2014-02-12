module SUSE
  module Connect
    # Extraction of dedicated class for Service representation
    class Service

      attr_reader :sources, :norefresh, :enabled

      def initialize(sources, enabled = [], norefresh = [])
        @sources    = sources
        @norefresh  = norefresh
        @enabled    = enabled
      end

    end
  end
end
