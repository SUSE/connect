module SUSE
  module Toolkit
    # Provides templates and partials interface
    module Renderer
      def initialize(*arguments)
        @templates = {}
        super
      end

      def render(filename, locals = {})
        bind = binding
        path = "../../connect/templates/#{filename}.erb"

        locals.each_pair do |key, value|
          bind.local_variable_set(key, value)
        end

        @templates[filename] ||= ERB.new File.read(File.expand_path(path, __FILE__)), 0, '-<>'
        @templates[filename].result(bind).gsub('\e', "\e")
      end

      def indent(level)
        ' ' * (level * 4)
      end
    end
  end
end
