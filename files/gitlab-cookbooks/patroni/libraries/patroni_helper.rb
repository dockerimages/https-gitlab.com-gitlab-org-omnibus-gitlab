class PatroniHelper < BaseHelper
  include ShellOutHelper

  DCS_ATTRIBUTES ||= %w(loop_wait ttl retry_timeout maximum_lag_on_failover max_timelines_history master_start_timeout).freeze
  DCS_POSTGRESQL_ATTRIBUTES ||= %w(use_pg_rewind use_slots).freeze

  attr_reader :node

  def ctl_command
    "#{node['package']['install-dir']}/embedded/bin/patronictl"
  end

  def service_name
    'patroni'
  end

  def running?
    OmnibusHelper.new(node).service_up?(service_name)
  end

  def bootstrapped?
    File.exist?(File.join(node['postgresql']['data_dir'], 'patroni.dynamic.json'))
  end

  def scope
    node['patroni']['scope']
  end

  def node_status
    return 'not running' unless running?

    cmd = "#{ctl_command} -c #{node['patroni']['dir']}/patroni.yaml list | grep #{node.name} | cut -d '|' -f 5"
    do_shell_out(cmd).stdout.chomp.strip
  end

  def repmgr_data_present?
    cmd = "/opt/gitlab/embedded/bin/repmgr -f #{node['postgresql']['dir']}/repmgr.conf cluster show"
    status = do_shell_out(cmd, node['postgresql']['username'])
    status.exitstatus.zero?
  end

  def dynamic_settings
    dcs = {
      'postgresql' => {
        'parameters' => {}
      },
      'slots' => {}
    }

    DCS_ATTRIBUTES.each do |key|
      dcs[key] = node['patroni'][key]
    end

    DCS_POSTGRESQL_ATTRIBUTES.each do |key|
      dcs['postgresql'][key] = node['patroni'][key]
    end

    node['patroni']['postgresql'].each do |key, value|
      dcs['postgresql']['parameters'][key] = value
    end

    node['patroni']['replication_slots'].each do |slot_name, options|
      dcs['slots'][slot_name] = parse_replication_slots_options(options)
    end

    if node['patroni']['standby_cluster']['enable']
      dcs['standby_cluster'] = {}

      node['patroni']['standby_cluster'].each do |key, value|
        next if key == 'enable'

        dcs['standby_cluster'][key] = value
      end
    end

    dcs
  end

  # pg_hba.conf entries
  def pg_hba_settings
    template = Chef::Resource::Template.new('pg_hba.conf', node.run_context)
    template.source 'pg_hba.conf.erb'
    template.cookbook 'postgresql'
    template.variables node['postgresql'].to_hash

    render_template(template)
  end

  def public_attributes
    return {} unless node['patroni']['enable']

    {
      'patroni' => {
        'config_dir' => node['patroni']['dir'],
        'data_dir' => node['patroni']['data_dir'],
        'log_dir' => node['patroni']['log_directory'],
        'api_address' => "#{node['patroni']['listen_address'] || '127.0.0.1'}:#{node['patroni']['port']}"
      }
    }
  end

  private

  # Parse replication slots attributes
  #
  # We currently support only physical replication
  def parse_replication_slots_options(options)
    return unless options['type'] == 'physical'

    {
      'type' => 'physical'
    }
  end

  # Render a Chef template
  #
  # @param [Chef::Resource::Template] template
  # @return String
  def render_template(template)
    template_finder = Chef::Provider::TemplateFinder.new(node.run_context, template.cookbook, node)
    template_path = template_finder.find(template.source)

    template_context = Chef::Mixin::Template::TemplateContext.new([])
    template_context.update({ node: node, template_finder: template_finder }.merge(template.variables))
    template_context._extend_modules(template.helper_modules)
    template_context.render_template(template_path)
  end
end
