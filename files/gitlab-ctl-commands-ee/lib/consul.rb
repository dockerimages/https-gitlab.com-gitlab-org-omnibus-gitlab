require 'mixlib/shellout'
require 'net/http'
require 'json'
require 'optparse'

require_relative 'repmgr'

class Consul
  WatcherError = Class.new(StandardError)

  attr_accessor :command, :subcommand

  def initialize(argv)
    @command = Kernel.const_get("#{self.class}::#{argv[3].capitalize}")
    @subcommand = argv[4].tr('-', '_') unless command.name == "Consul::Upgrade"
  end

  def execute
    if command.name == "Consul::Upgrade"
      Upgrade.roll
    else
      command.send(subcommand, $stdin.gets)
    end
  end

  class Upgrade
    attr_reader :hostname
    attr_reader :nodes
    attr_reader :rejoin_wait_loops

    ConsulNode = Struct.new(:address, :server?, :leader?, :voter?)

    def initialize(machine_name)
      @hostname = machine_name
      @nodes = {}
      node_attributes = GitlabCtl::Util.get_node_attributes
      rejoin_wait_loops = node_attributes['consul']['rejoin_wait_loops']
      @rejoin_wait_loops = rejoin_wait_loops if rejoin_wait_loops.is_a? Integer
      @rejoin_wait_loops ||= 10
      @rolled = false

      discover_nodes
    end

    def healthy?
      healthy = true
      @nodes.select { |n, d| d.server? }.each do |name, info|
        health_uri = URI("http://127.0.0.1:8500/v1/health/node/#{name}")
        data = JSON.parse(Net::HTTP.get(health_uri))
        data.each do |node|
          healthy &&= node["Status"] == "passing"
          @rolled = node["Status"] == "passing" if name.start_with?(@hostname)
        end
      rescue Errno::ECONNREFUSED
        healthy = false
        @rolled = false if name.start_with?(@hostname)
        next
      rescue JSON::ParserError
        healthy = false
        @rolled = false if name.start_with?(@hostname)
        next
      end
      healthy
    end

    def discover_nodes
      member_uri = URI("http://127.0.0.1:8500/v1/agent/members")
      server_uri = URI('http://127.0.0.1:8500/v1/operator/raft/configuration')
      raft_configs = JSON.parse(Net::HTTP.get(server_uri))
      member_data = JSON.parse(Net::HTTP.get(member_uri))

      member_data.each do |node|
        name = node["Name"]
        config = raft_configs["Servers"].find { |s| s["Node"] == name }

        server = !config.nil?
        leader = server ? config["Leader"] : false
        voter = server ? config["Voter"] : false

        @nodes[name] = ConsulNode.new(node["Addr"], server, leader, voter)
      end
    end

    def leave
      command = Mixlib::ShellOut.new("/opt/gitlab/embedded/bin/consul leave")
      command.run_command
      begin
        command.error!
      rescue StandardError => e
        warn(e)
        warn(command.stderr)
      end
    end

    class << self
      def roll(node_name = Socket.gethostname)
        upgrade = new(Socket.gethostname)
        raise "#{upgrade.hostname} will not be rolled due to unhealthy cluster!" unless upgrade.healthy?

        upgrade.leave
        upgrade.rejoin_wait_loops.times do
          break if upgrade.healthy?

          puts "Waiting on init system to restart Consul"
          sleep(5)
        end

        # because of how healthy works, invoke once and store final values
        final_health = upgrade.healthy?
        cluster_status = final_health ? "healthy" : "unhealthy"
        node_status = @rolled ? "restarted" : "stopped"

        raise "#{upgrade.hostname} #{node_status}, cluster #{cluster_status}" unless cluster_status && node_status

        puts "Consul upgraded successfully!"
      end
    end
  end

  class Kv
    class << self
      def put(key, value = nil)
        run_consul("kv put #{key} #{value}")
      end

      def delete(key)
        run_consul("kv delete #{key}")
      end

      protected

      def run_consul(cmd)
        command = Mixlib::ShellOut.new("/opt/gitlab/embedded/bin/consul #{cmd}")
        command.run_command
        begin
          command.error!
        rescue StandardError => e
          puts e
          puts command.stderr
        end
      end
    end
  end

  class Watchers
    class << self
      def handle_failed_master(input)
        return if input.chomp.eql?('null')

        node = Repmgr::Node.new
        unless node.is_master?
          # wait 5 seconds for the actual master node to handle the removal
          sleep 5
          return
        end

        begin
          data = JSON.parse(input)
        rescue JSON::ParserError
          raise Consul::WatcherError, "Invalid input detected: '#{input}'"
        end

        data.each do |fm|
          node_id = fm['Key'].split('/').last
          begin
            Repmgr::Master.remove(node_id: node_id, user: 'gitlab-consul')
          rescue StandardError
            Consul::Kv.put(fm['Key'])
          else
            Consul::Kv.delete(fm['Key'])
          end
        end
      end
    end
  end
end
