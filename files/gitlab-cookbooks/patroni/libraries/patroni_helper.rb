class PatroniHelper < BaseHelper
  include ShellOutHelper

  attr_reader :node

  def service_name
    'patroni'
  end

  def running?
    OmnibusHelper.new(node).service_up?(service_name)
  end

  def bootstrapped?
    File.exist?(File.join(node['postgresql']['data_dir'], 'patroni.dynamic.json'))
  end

  def initialized?
    success? "/opt/gitlab/embedded/bin/consul kv get service/#{scope}/initialize"
  end

  def scope
    node['patroni']['scope']
  end

  def node_status
    return 'not running' unless running?

    cmd = "#{node['patroni']['ctl_command']} -c #{node['patroni']['dir']}/patroni.yaml list | grep #{node.name} | cut -d '|' -f 6"
    do_shell_out(cmd).stdout.chomp.strip
  end

  def public_attributes
    return {} unless Gitlab['patroni']['enable']

    {
      'patroni' => {
        'config_dir' => node['patroni']['dir'],
        'data_dir' => node['patroni']['data_dir'],
        'log_dir' => node['patroni']['log_directory'],
        'api_address' => "#{node['patroni']['connect_address']}:#{node['patroni']['api_port']}"
      }
    }
  end
end
