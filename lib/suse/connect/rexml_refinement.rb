module SUSE
  module Connect
    # Refinement for Rexml::Element which allows us simply to_hash elements and get products as array of hashes
    module RexmlRefinement
      REXML::Element.class_eval do
        def to_hash
          attributes.reduce({}) do |mem, attr|
            mem[attr.first.to_sym] = attr.last
            mem
          end
        end
      end
    end
  end
end
