require_relative 'base_helper'

# Helper class to interact with bundled Patroni service
class PatroniHelper < BaseHelper
  include ShellOutHelper
  attr_reader :node

  # internal name for the service (node['gitlab'][service_name])
  def service_name
    'patroni'
  end

  def is_running?
    OmnibusHelper.new(node).service_up?(service_name)
  end

  def enabled?
    OmnibusHelper.new(node).service_enabled?(service_name)
  end

  def start
    cmd = '/opt/gitlab/bin/gitlab-ctl start patroni'
    success?(cmd) unless is_running?
  end

  def stop
    cmd = '/opt/gitlab/bin/gitlab-ctl stop patroni'
    success?(cmd) if is_running
  end

  def node_bootstrapped?
    File.exist?(File.join(node['postgresql']['data_dir'], 'patroni.dynamic.json'))
  end

  def is_master?
    return false unless cluster_initialized?

    cmd = "/opt/gitlab/embedded/bin/consul kv get service/#{scope}/leader"
    leader = do_shell_out(cmd).stdout.chomp
    leader == node.name
  end

  def cluster_initialized?
    cmd = "/opt/gitlab/embedded/bin/consul kv get service/#{scope}/initialize"
    success?(cmd)
  end

  def scope
    node['patroni']['config']['scope']
  end

  def master_on_initialization
    node['patroni']['master_on_initialization']
  end

  def node_status
    return 'not running' unless is_running?

    cmd = "/opt/gitlab/bin/gitlab-patronictl list | grep #{node.name} | cut -d '|' -f 6"
    do_shell_out(cmd).stdout.chomp.strip
  end
end
