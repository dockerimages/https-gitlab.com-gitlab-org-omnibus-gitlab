require 'mixlib/shellout'
require 'net/http'
require 'json'
require 'optparse'

require_relative 'repmgr'

class Consul
  WatcherError = Class.new(StandardError)

  attr_accessor :command, :subcommand, :extra_args

  class << self
    def valid_actions
      %w[upgrade kv watcher]
    end
  end

  def initialize(argv)
    potential_command = argv[3].capitalize

    begin
      @command = Kernel.const_get("#{self.class}::#{potential_command}")
    rescue RuntimeError, NameError
      raise "#{potential_command} invalid: consul accepts actions #{Consul.valid_actions.join(', ')}"
    end

    target_method = argv[4].nil? ? "default" : argv[4].tr('-', '_')
    arguments = argv[4..-1]

    if command.respond_to? target_method
      @extra_args = arguments[1..-1]
      @subcommand = target_method
    else
      @extra_args = arguments
      @subcommand = "default"
    end

    raise ArgumentError, "#{target_method} is not a valid option" unless command.respond_to? subcommand
  end

  def execute
    command.send(subcommand, extra_args)
  end

  class Upgrade
    attr_reader :hostname, :timeout
    attr_accessor :finished_healthy, :started_healthy, :rolled, :gossip_delay

    NodeInfo = Struct.new(:name, :status)

    def initialize(machine_name, args)
      gossip_delay = 3
      @hostname = machine_name

      opts = parse_options(args.nil? ? [] : args)
      @timeout = opts[:timeout]

      @started_healthy, @rolled = health_check
      @finished_healthy = false
    end

    def finished_healthy?
      @finished_healthy
    end

    def started_healthy?
      @started_healthy
    end

    def rolled?
      @rolled
    end

    def parse_options(args)
      options = {
        timeout: 100
      }

      OptionParser.new do |opts|
        opts.on('-t', '--timeout [INTEGER]', Integer,
                'Time in seconds to wait for a healthy cluster after roll') do |r|
          options[:timeout] = r if r.is_a? Integer
        end
      end.parse!(args)

      options
    end

    def health_check
      begin
        health_uri = URI('http://127.0.0.1:8500/v1/health/service/consul')
        health = JSON.parse(Net::HTTP.get(health_uri))
        statuses = health.map { |n| n['Checks'].map { |c| NodeInfo.new(c['Node'], c['Status']) }.flatten }.flatten
        healthy = statuses.detect { |n| n.status != 'passing' }.nil?
        rolled = statuses.detect { |n| n.name.start_with?(@hostname) && n.status != 'passing' }.nil?
      rescue Errno::ECONNREFUSED, JSON::ParserError
        healthy = false
        rolled = false
      end

      [healthy, rolled]
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

    def roll
      raise "#{hostname} will not be rolled due to unhealthy cluster!" unless started_healthy?

      leave

      sleep(gossip_delay) # allow gossip protocol time to see node leave

      remaining_seconds = timeout
      while remaining_seconds >= 0
        puts "Waiting on init system to restart Consul"

        sleep(5)

        remaining_seconds -= 5

        @finished_healthy, @rolled = health_check

        if rolled?
          sleep(gossip_delay) # allow gossip protocol to inform other nodes
          break
        end
      end

      cluster_status = finished_healthy? ? "healthy" : "unhealthy"
      node_status = rolled? ? "restarted" : "stopped"

      raise "#{hostname} #{node_status}, cluster #{cluster_status}" unless finished_healthy? && rolled?

      puts "Consul upgraded successfully!"
    end

    class << self
      def default(args = nil)
        upgrade = new(Socket.gethostname, args)
        upgrade.roll
      end
    end
  end

  class Kv
    class << self
      def put(args = [])
        raise ArgumentError, "Expect `<key> <value>` or `<key>`, got #{args.size} arguments!" unless [1, 2].include? args.size

        key, value = args
        run_consul("kv put #{key} #{value}")
      end

      def delete(args = [])
        raise ArgumentError, "Expected only `<key>`, got #{args.size} arguments!" if args.size != 1

        key = args[0]
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
      def handle_failed_master(extra_args)
        input = $stdin.gets
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
