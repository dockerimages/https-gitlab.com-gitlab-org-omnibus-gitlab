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
    unless is_running?
      cmd = '/opt/gitlab/bin/gitlab-ctl start patroni'
      success?(cmd)
    end
  end

  def stop
    if is_running?
      cmd = '/opt/gitlab/bin/gitlab-ctl stop patroni'
      success?(cmd)
    end
  end

end
