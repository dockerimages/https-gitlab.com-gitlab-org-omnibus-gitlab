require_relative 'base_pg_helper'
require_relative 'patroni_helper'

# Helper class to interact with bundled Patroni PostgreSQL instance
class PatroniPgHelper < BasePgHelper
  include ShellOutHelper

  # internal name for the service (node[service_name])
  def service_name
    'patroni-postgresql'
  end

  # command wrapper name
  def service_cmd
    'gitlab-psql'
  end

  def is_running?
    # when patroni is controling postgresql, runit service can't determine if postgresql is running
    # use pg_isready to determine postgresql status
    PatroniHelper.new(node).is_running? && pg_isready?('localhost')
  end

  def should_notify?
    # when patroni is controling postgresql, runit service can't determine if postgresql is running
    # use pg_isready to determine postgresql status
    PatroniHelper.new(node).should_notify? && pg_isready?('localhost')
  end

  def reload
    return unless is_running?
    psql_cmd(["-d 'template1'",
              %(-c "select pg_reload_conf();" -tA)])
  end

  def start
    return if is_running?
    patroni_helper = PatroniHelper.new(node)
    patroni_helper.start
  end
end
