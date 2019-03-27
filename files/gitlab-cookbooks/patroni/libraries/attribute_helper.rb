
module Patroni
  module AttributesHelper
    extend self

    def populate_missing_values(node)
      assign_postgresql_directories(node)
      assign_postgresql_parameters(node)
      assign_postgresql_users(node)
      assign_connect_addresses(node)
    end

    private

    def assign_connect_addresses(node)
      address_detector     = Patroni::AddressDetector.new(node, node['patroni']['bind_interface'])
      postgres_listen_port = node['gitlab']['postgresql']['port']
      patroni_listen_port  = node['patroni']['config']['restapi']['listen'].split(':').last

      node.default['patroni']['config']['restapi']['connect_address']    = "#{address_detector.ipaddress}:#{patroni_listen_port}"
      node.default['patroni']['config']['postgresql']['connect_address'] = "#{address_detector.ipaddress}:#{postgres_listen_port}"
    end

    def assign_postgresql_directories(node)
      node.default['patroni']['config']['postgresql']['data_dir']   =  File.join(node['gitlab']['postgresql']['dir'], "data")
      node.default['patroni']['config']['postgresql']['config_dir'] = node['gitlab']['postgresql']['data_dir']
      node.default['patroni']['config']['postgresql']['bin_dir'] = "/opt/gitlab/embedded/bin/"
    end

    def assign_postgresql_parameters(node)
      node.default['patroni']['config']['postgresql']['listen'] = node['gitlab']['postgresql']['listen_address']
      node.default['patroni']['config']['postgresql']['parameters']['port'] = node['gitlab']['postgresql']['port']
      node.default['patroni']['config']['postgresql']['parameters']['ssl'] = node['gitlab']['postgresql']['ssl']
      node.default['patroni']['config']['postgresql']['parameters']['ssl_ciphers'] = node['gitlab']['postgresql']['ssl_ciphers']
      node.default['patroni']['config']['postgresql']['parameters']['log_destination'] = 'syslog'

      # node.default['patroni']['config']['postgresql']['parameters'] = node['gitlab']['postgresql']['parameters']
    end

    def assign_postgresql_users(node)
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
