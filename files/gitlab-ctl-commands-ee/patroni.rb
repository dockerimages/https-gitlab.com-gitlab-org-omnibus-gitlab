require 'optparse'

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/patroni"
require "#{base_path}/embedded/service/omnibus-ctl/lib/postgresql"

add_command_under_category('patroni', 'database', 'Interact with Patroni', 2) do
  begin
    options = Patroni.parse_options(ARGV)
  rescue OptionParser::ParseError => e
    warn e
    Kernel.exit 128
  end

  case options[:command]
  when 'bootstrap'
    Patroni.bootstrap options
  when 'check-leader'
    Patroni.check_leader options
  when 'check-replica'
    Patroni.check_replica options
  end
end
