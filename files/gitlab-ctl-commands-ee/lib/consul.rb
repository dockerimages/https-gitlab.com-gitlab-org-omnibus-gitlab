require 'mixlib/shellout'

require_relative 'repmgr'

class Consul
  WatcherError = Class.new(StandardError)

  attr_accessor :command, :subcommand, :input

  def initialize(argv, input = nil)
    @command = Kernel.const_get("#{self.class}::#{argv[3].capitalize}")
    @subcommand = argv[4].tr('-', '_')
    @input = input
  end

  def execute
    command.send(subcommand, input)
  end

  class Upgrade
    attr_reader :hostname
    attr_reader :nodes

    ConsulNode = Struct.new(:address, :server?, :leader?, :voter?)

    def initialize(machine_name)
      @hostname = machine_name
      @nodes = {}
      discover_nodes
    end

    def healthy?
      healthy = true
      begin
        @nodes.select { |n, d| d.server? }.each do |name, info|
          health_uri = URI("http://127.0.0.1:8500/v1/health/node/#{name}")
          data = JSON.parse(Net::HTTP.get(health_uri))
          data.each do |node|
            healthy &&= node["Status"] == "passing"
          end
        end
      rescue Errno::ECONNREFUSED
        healthy = false
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
          puts e
          puts command.stderr
        end
    end

    class << self
      def roll
        upgrade = new(Socket.gethostname)
        MyModule::Upgrade.fail unless upgrade.healthy?
        upgrade.leave
        10.times do
          break if upgrade.healthy?
          puts "waiting on restart"
          sleep(5)
        end

        raise "#{upgrade.host_name} failed to restart!" unless upgrade.healthy?
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
