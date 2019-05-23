resource_name :consul_service

property :service_name, String, name_property: true
property :ip_address, [String, nil], default: nil
property :port, [Integer, nil], default: nil

# Combined address plus port - 0.0.0.0:1234
property :socket_address, [String, nil], default: nil

action :create do
  if property_is_set?(:socket_address)
    ip_address, port = new_resource.socket_address.split(':')
    ip_address = translate_address(ip_address)
  elsif property_is_set?(:ip_address) && property_is_set?(:port)
    ip_address = translate_address(new_resource.ip_address)
    port = new_resource.port
  else
    raise "Missing required properties: `socket_address` or both `ip_address` and `port`."
  end

  service_name = sanitize_service_name(new_resource.service_name)

  content = {
    'service' => {
      'name'    => service_name,
      'address' => ip_address,
      'port'    => port.to_i
    }
  }

  account_helper = AccountHelper.new(node)

  file "#{node['consul']['config_dir']}/#{service_name}-service.json" do
    content content.to_json
    owner account_helper.consul_user
    notifies :run, 'execute[reload consul]'
  end
end

action :delete do
  service_name = sanitize_service_name(new_resource.service_name)

  file "#{node['consul']['config_dir']}/#{service_name}-service.json" do
    action :delete
    notifies :run, 'execute[reload consul]'
  end
end

# Consul allows dashes but not underscores for DNS service discovery.
# Avoid logging errors by changing all underscores to dashes.
def sanitize_service_name(name)
  name.tr('_', '-')
end

# A listen address of 0.0.0.0 binds to all interfaces.
# Translate that listen address to the node's actual
# IP address so external services know where to connect.
def translate_address(address)
  return node['ipaddress'] if ['0.0.0.0', '*'].include?(address)

  # TODO: Handle this better. Should we automatically change exporters to
  # TODO: 0.0.0.0 in some circumstances? We probably need to balance
  # TODO: ease-of-configuration and security here.
  if ['localhost', '127.0.0.1'].include?(address)
    raise "Service cannot be listening on 'localhost'."
  end

  address
end
