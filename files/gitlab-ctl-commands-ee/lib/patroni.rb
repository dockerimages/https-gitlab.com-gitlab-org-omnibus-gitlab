require 'net/http'
require 'optparse'

module Patroni
  ClientError = Class.new(StandardError)

  def self.parse_options(args)
    # throw away arguments that initiated this command
    loop do
      break if args.shift == 'patroni'
    end

    options = {}

    global = OptionParser.new do |opts|
      opts.banner = 'patroni [options] command [options]'
      opts.on('-q', '--quiet', 'Silent or quiet mode') do |q|
        options[:quiet] = q
      end
      opts.on('-v', '--verbose', 'Verbose or debug mode') do |v|
        options[:verbose] = v
      end
      opts.on('-h', '--help', 'Usage help') do
        warn usage
        Kernel.exit 1
      end
    end

    commands = {
      'check-leader' => OptionParser.new,
      'check-replica' => OptionParser.new
    }

    global.order! args

    command = args.shift

    raise OptionParser::ParseError, "unspecified Patroni command" \
      if command.nil? || command.empty?

    raise OptionParser::ParseError, "unknown Patroni command: #{command}" \
      unless commands.key? command

    options[:command] = command
    commands[command].order! args

    options
  end

  def self.usage()
    <<-USAGE
Usage:
  gitlab-ctl patroni [options] command [options]

  GLOBAL OPTIONS:
    -h, --help      Usage help
    -q, --quiet     Silent or quiet mode
    -v, --verbose   Verbose or debug mode

  COMMANDS:
    check-leader    Check if the current node is the Patroni leader
    check-replica   Check if the current node is a Patroni replica
USAGE
  end

  def self.check_leader(options)
    client = Client.new
    begin
      if client.leader?
        warn "I am the leader." unless options[:quiet]
        Kernel.exit 0
      else
        warn "I am not the leader." unless options[:quiet]
        Kernel.exit 1
      end
    rescue StandardError => e
      warn "Error while checking the role of the current node: #{e}" unless options[:quiet]
      Kernel.exit 3
    end
  end

  def self.check_replica(options)
    client = Patroni::Client.new
    begin
      if client.replica?
        warn "I am a replica." unless options[:quiet]
        Kernel.exit 0
      else
        warn "I am not a replica." unless options[:quiet]
        Kernel.exit 1
      end
    rescue StandardError => e
      warn "Error while checking the role of the current node: #{e}" unless options[:quiet]
      Kernel.exit 3
    end
  end

  class Client
    attr_accessor :uri

    def initialize
      attributes = GitlabCtl::Util.get_node_attributes
      api_host = attributes['patroni']['restapi']['listen_ip'] || 'localhost'
      api_port = attributes['patroni']['restapi']['port']
      @uri = URI("http://#{api_host}:#{api_port}")
    end

    def leader?
      get('/leader') do |response|
        response.code == '200'
      end
    end

    def replica?
      get('/replica') do |response|
        response.code == '200'
      end
    end

    private

    def get(endpoint, header = nil)
      Net::HTTP.start(@uri.host, @uri.port) do |http|
        http.request_get(endpoint, header) do |response|
          return yield response
        end
      end
    end
  end
end
