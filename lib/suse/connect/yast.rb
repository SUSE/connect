# YaST class provides methods emulating SCC's API.
class SUSE::Connect::YaST

  class << self

    def delegate_methods(*methods_and_args)
      @methods_and_args = methods_and_args.reduce({}) do |hash, pair|
        hash.merge!(pair)
      end
    end

    def method_missing(name, param_hash = {})
      if @methods_and_args.keys.include?(name)
        required = @methods_and_args[name].map do |param|
          param_hash[param]
        end
        # Delegate specified methods to an instance of Client.
        # Required parameters get extracted from params_hash and passed
        # explicitly as arguments to the specified method.
        Client.new(param_hash).send(name, *required)
      end
    end

  end

  delegate_methods :announce_system => [],
                   :activate_product => [:product_ident],
                   :list_products => [:product_ident]

end
