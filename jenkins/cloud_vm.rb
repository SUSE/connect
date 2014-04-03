require 'openstack'
require 'fileutils'

module Cloud
  # Access cloud.suse.de opentsack API
  class VM
    class << self
      def connection
        if ENV['CLOUD_USER'] && ENV['CLOUD_PASS']
          @connection ||= OpenStack::Connection.create(
            :username => ENV['CLOUD_USER'],
            :api_key => ENV['CLOUD_PASS'],
            :auth_method => 'password',
            :auth_url => 'https://dashboardp2.cloud.suse.de:5000/v2.0',
            :authtenant_name => 'appliances',
            :service_type => 'compute'
          )
        else
          puts 'ERROR: Environment variable CLOUD_USER or CLOUD_PASS is not defined'
          exit(1)
        end
      end

      def create(name = 'SUSEConnect_testing')
        image = connection.get_image('77a84bd3-bd75-4c0d-b007-80a3f0646fe5')
        flavor = connection.get_flavor(2)
        address = connection.get_floating_ips.select {|ip| ip.instance_id.nil? }.first || connection.create_floating_ip

        puts "*** Creating new '#{name}' VM ..."
        server = connection.create_server(:name => name, :imageRef => image.id, :flavorRef => flavor.id)

        delay = (ENV['TIME_WAIT'] || 10).to_i

        puts "*** Waiting #{delay} seconds for the machine to boot ..."
        sleep(delay) # Wait 10 seconds until machine gets initialized

        puts "*** Attaching floating ip '#{address.ip}' to '#{name}' VM ..."
        connection.attach_floating_ip(:server_id => server.id, :ip_id => address.id)

        puts '*** Creating node configuration file #{address.ip}.json ...'
        create_node_file(address.ip)

        server
      end

      def destroy(name = 'SUSEConnect_testing')
        vm = connection.servers.find {|s| s[:name] == name }
        if vm
          vm = connection.get_server vm[:id]
          vm.delete!
        else
          puts "ERROR: Cann't find VM with name '#{name}'"
        end
      end

      def create_node_file(ip)
        dir = File.join(File.expand_path(File.dirname(__FILE__)), '../kitchen/nodes')
        src = File.join(dir, 'template.json')
        dest = File.join(dir, "#{ip}.json")
        FileUtils.cp(src, dest)
      end
    end
  end
end
