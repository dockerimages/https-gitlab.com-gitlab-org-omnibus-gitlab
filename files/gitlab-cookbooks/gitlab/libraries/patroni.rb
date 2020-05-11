
module Patroni
  class << self
    def parse_variables
      if node['patroni']['connect_address'].nil?
        node['patroni']['connect_address'] = AddressHelper.private_ipv4_list[0]
      end
    end
  end
end
