module Patroni
  class AddressDetector
    attr_reader :node, :bind_interface

    def initialize(node, bind_interface)
      @node = node
      @bind_interface = bind_interface
    end

    def ipaddress
      @ipaddress ||= interface['addresses'].detect { |_k, v| v['family'] == 'inet' }.first
    end

    private

    def interface
      return specific_interface if bind_interface

      interfaces.select { |_k, v| v['encapsulation'] == 'Ethernet' }.values.first
    end

    def specific_interface
      raise "Interface '#{bind_interface}' doesn't exists" unless interfaces[bind_interface]

      interfaces[bind_interface]
    end

    def interfaces
      node['network']['interfaces']
    end
  end
end
