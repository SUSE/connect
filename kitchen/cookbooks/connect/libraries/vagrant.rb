class Chef::Recipe
  module Scc
    class Checker
      def self.deployed?(project_name)
        ::File.exists?("/var/www/#{project_name}/current")
      end
    end
  end
end
