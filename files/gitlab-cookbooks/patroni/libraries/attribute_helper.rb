module Patroni
  module AttributesHelper
    extend self

    def populate_missing_values(node)
      assign_postgresql_directories(node)
      assign_postgresql_parameters(node)
      assign_pg_hba_entries(node)
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
      postgres_listen_port = node['postgresql']['port']
      patroni_api_listen_ip = node['patroni']['restapi']['listen_ip']
      patroni_api_port = node['patroni']['restapi']['port']

      node.default['patroni']['config']['restapi']['connect_address'] = "#{ipaddress}:#{patroni_api_port}"
      node.default['patroni']['config']['restapi']['listen'] = "#{patroni_api_listen_ip}:#{patroni_api_port}"
      node.default['patroni']['config']['postgresql']['connect_address'] = "#{ipaddress}:#{postgres_listen_port}"
    end

    def assign_postgresql_directories(node)
      node.default['patroni']['config']['postgresql']['data_dir']   = node['postgresql']['data_dir']
      node.default['patroni']['config']['postgresql']['config_dir'] = node['postgresql']['data_dir']
      node.default['patroni']['config']['postgresql']['bin_dir'] = "/opt/gitlab/embedded/bin/"
    end

    def assign_postgresql_parameters(node)
      node.default['patroni']['config']['postgresql']['listen'] = "#{node['postgresql']['listen_address']}:#{node['postgresql']['port']}"
      node.default['patroni']['config']['postgresql']['use_unix_socket'] = true
      node.default['patroni']['config']['postgresql']['parameters']['unix_socket_directories'] = node['postgresql']['unix_socket_directory']
    end

    def assign_pg_hba_entries(node)
      node.default['patroni']['config']['postgresql']['pg_hba'] = [
        "local all all trust",
        "local replication #{node['patroni']['users']['replication']['username']} trust"
      ]
      node['postgresql']['trust_auth_cidr_addresses'].each do |cidr|
        node.default['patroni']['config']['postgresql']['pg_hba'] << "host all all #{cidr} trust"
        node.default['patroni']['config']['postgresql']['pg_hba'] << "host replication #{node['patroni']['users']['replication']['username']} #{cidr} trust"
      end
      node['postgresql']['md5_auth_cidr_addresses'].each do |cidr|
        node.default['patroni']['config']['postgresql']['pg_hba'] << "host all all #{cidr} md5"
      end
    end

    def assign_postgresql_user(node)
      node['patroni']['users'].each do |type, params|
        username = params['username']
        password = params['password']

        node.default['patroni']['config']['postgresql']['authentication'][type]['username'] = username
        node.default['patroni']['config']['postgresql']['authentication'][type]['password'] = password
      end
    end
  end
end
