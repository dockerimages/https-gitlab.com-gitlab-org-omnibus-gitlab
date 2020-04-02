class ConsulPatroniHelper
  def self.populate_service_config(node)
    return unless node['consul']['service_config'].nil?

    preferred_config = node['patroni']['enable'] ? 'patroni' : 'repmgr'
    node.default['consul']['service_config'] = Chef::Mixin::DeepMerge.deep_merge(
      node['consul']['internal']['service_config'][preferred_config],
      node['consul']['internal']['service_config']['postgresql'])
  end
end
