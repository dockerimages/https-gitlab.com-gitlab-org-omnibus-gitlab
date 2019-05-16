require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/patroni"
require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"

add_command_under_category('patroni', 'database', 'Manage patroni PostgreSQL cluster nodes', 2) do |_cmd_name, _args|

  patroni = Patroni.new()
  results = patroni.patroni_cmd(ARGV)
  log results
end
