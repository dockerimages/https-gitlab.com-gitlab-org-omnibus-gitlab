require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/patroni"

add_command_under_category('check-leader', 'patroni', 'Check if the current node is the Patroni leader', 2) do
  client = Patroni::Client.new
  begin
    if client.leader?
      warn "I am the leader."
      Kernel.exit 0
    else
      warn "I am not the leader."
      Kernel.exit 1
    end
  rescue StandardError => e
    warn "Error while checking the role of the current node: #{e}"
    Kernel.exit 3
  end
end

add_command_under_category('check-replica', 'patroni', 'Check if the current node is a Patroni replica', 2) do
  client = Patroni::Client.new
  begin
    if client.replica?
      warn "I am a replica."
      Kernel.exit 0
    else
      warn "I am not a replica."
      Kernel.exit 1
    end
  rescue StandardError => e
    warn "Error while checking the role of the current node: #{e}"
    Kernel.exit 3
  end
end
