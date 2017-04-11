module SUSE
  module Toolkit
    # Provides templates and partials interface
    module Renderer
      def initialize(*arguments)
        @templates = {}
        super
      end

      def render(filename, locals: binding)
        bind = locals.is_a?(Binding) ? locals : OpenStruct.new(locals).instance_eval { binding }
        @templates[filename] ||= ERB.new File.read(File.expand_path("../../connect/templates/#{filename}.erb", __FILE__)), 0, '-<>'
        @templates[filename].result(bind).gsub('\e', "\e")
      end
    end
  end
end
