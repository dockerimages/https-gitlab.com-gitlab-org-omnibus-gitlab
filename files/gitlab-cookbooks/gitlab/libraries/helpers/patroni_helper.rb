require_relative 'base_helper'

# Helper class to interact with bundled Patroni service
class PatroniHelper < BaseHelper
  include ShellOutHelper
  attr_reader :node

  # internal name for the service (node['gitlab'][service_name])
  def service_name
    'patroni'
  end

  def running?
    OmnibusHelper.new(node).service_up?(service_name)
  end

  def enabled?
    OmnibusHelper.new(node).service_enabled?(service_name)
  end

  def should_notify?
    OmnibusHelper.new(node).should_notify?(service_name)
  end

  def start
    cmd = '/opt/gitlab/bin/gitlab-ctl start patroni'
    success?(cmd) unless running?
  end

  def stop
    cmd = '/opt/gitlab/bin/gitlab-ctl stop patroni'
    success?(cmd) if running?
  end

  def node_bootstrapped?
    File.exist?(File.join(node['postgresql']['data_dir'], 'patroni.dynamic.json'))
  end

  def master?
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
    return 'not running' unless running?

    cmd = "/opt/gitlab/bin/gitlab-patronictl list | grep #{node.name} | cut -d '|' -f 6"
    do_shell_out(cmd).stdout.chomp.strip
  end

  def public_attributes
    {
      service_name => {
        'api' => {
          'connect_address': node['patroni']['config']['restapi']['connect_address']
        }
      }
    }
  end
end
