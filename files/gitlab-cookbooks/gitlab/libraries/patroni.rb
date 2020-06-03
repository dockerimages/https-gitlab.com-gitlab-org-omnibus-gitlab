require 'socket'

module Patroni
  class << self
    def parse_variables
      Gitlab['patroni']['connect_address'] ||= private_ipv4 || Gitlab['node']['ipaddress']
    end

    def private_ipv4
      Socket.getifaddrs.select { |ifaddr| ifaddr.addr.ipv4_private? }.first.addr.ip_address
    end
  end
end
