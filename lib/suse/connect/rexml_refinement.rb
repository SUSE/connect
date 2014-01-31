module SUSE
  module Connect
    module RexmlRefinement

      refine REXML::Element do
        def to_hash
          attributes.inject({}) {|mem, attr| mem[attr.first.to_sym] = attr.last; mem}
        end
      end

    end
  end
end
