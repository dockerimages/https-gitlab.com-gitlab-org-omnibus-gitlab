require 'socket'

module AddressHelper
  class << self
    def private_ipv4_list
      Socket.ip_address_list.select(&:ipv4_private?).map(&:ip_address)
    end

    def public_ipv4_list
      Socket.ip_address_list.select { |intf| intf.ipv4? && !intf.ipv4_loopback? && !intf.ipv4_multicast? && !intf.ipv4_private? }.map(&:ip_address)
    end
  end
end
