class ConsulPatroniHelper
  def self.populate_service_config(node)
    return unless node['consul']['service_config'].nil?

    preferred_config = node['patroni']['enable'] ? 'patroni' : 'repmgr'
    Chef::Mixin::DeepMerge.deep_merge!(
      node['consul'][preferred_config]['service_config'],
      node.default['consul']['service_config'])
  end
end
