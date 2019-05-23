
module Patroni
  module AttributesHelper
    extend self

    def populate_missing_values(node)
      assign_postgresql_directories(node)
      assign_postgresql_parameters(node)
      assign_postgresql_user(node)
      assign_connect_addresses(node)
    end

    private

    def assign_connect_addresses(node)
      if node['patroni']['private_ipaddress'].nil?
        private_ip_list = AddressHelper.private_ipv4_list
        raise "Multiple private IPs found. Please configure one for patroni['private_ipaddress'] in gitlab.rb" if private_ip_list.count > 1

        ipaddress = private_ip_list[0]
      else
        ipaddress = node['patroni']['private_ipaddress']
      end
      postgres_listen_port = node['gitlab']['postgresql']['port']
      patroni_listen_port  = node['patroni']['config']['restapi']['listen'].split(':').last

      node.default['patroni']['config']['restapi']['connect_address']    = "#{ipaddress}:#{patroni_listen_port}"
      node.default['patroni']['config']['postgresql']['connect_address'] = "#{ipaddress}:#{postgres_listen_port}"
    end

    def assign_postgresql_directories(node)
      node.default['patroni']['config']['postgresql']['data_dir']   = node['gitlab']['postgresql']['data_dir']
      node.default['patroni']['config']['postgresql']['config_dir'] = node['gitlab']['postgresql']['data_dir']
      node.default['patroni']['config']['postgresql']['bin_dir'] = "/opt/gitlab/embedded/bin/"
    end

    def assign_postgresql_parameters(node)
      node.default['patroni']['config']['postgresql']['listen'] = "#{node['patroni']['postgresql_listen_address']}:#{node['gitlab']['postgresql']['port']}"
      node.default['patroni']['config']['postgresql']['parameters']['hba_file'] = "#{node['gitlab']['postgresql']['data_dir']}/pg_hba.conf"
    end

    def assign_postgresql_user(node)
      node['patroni']['users'].each do |type, params|
        username = params['username']
        password = params['password']
        options  = params['options']

        node.default['patroni']['config']['bootstrap']['users'][username]['password'] = password
        node.default['patroni']['config']['bootstrap']['users'][username]['options'] = options
        node.default['patroni']['config']['postgresql']['authentication'][type]['username'] = username
        node.default['patroni']['config']['postgresql']['authentication'][type]['password'] = password
      end
    end
  end
end
