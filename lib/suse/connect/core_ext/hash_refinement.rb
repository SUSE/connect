module SUSE
  module Connect
    module CoreExt
      # Extends a Hash class with a to_openstruct method
      module HashRefinement
        refine ::Hash do
          def to_openstruct
            OpenStruct.new self
          end
        end
      end
    end
  end
end
