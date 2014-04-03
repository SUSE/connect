module SUSE
  module Connect
    # Extraction of dedicated class for Service representation
    class Service

      attr_reader :sources, :norefresh, :enabled

      def initialize(sources, enabled = [], norefresh = [])
        @sources = []
        sources.each do |service_name, source_url|
          @sources << Source.new(service_name, source_url)
        end
        @norefresh  = norefresh
        @enabled    = enabled
      end

    end
  end
end
