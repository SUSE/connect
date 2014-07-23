module SUSE
  module Connect
    # System class allowing to interact with underlying system
    class System
      extend SUSE::Toolkit::SystemCalls
      extend SUSE::Connect::Archs::Generic
      module_to_use = Object.const_get("SUSE::Connect::Archs::#{self.arch.capitalize}")
      extend module_to_use
    end
  end
end
