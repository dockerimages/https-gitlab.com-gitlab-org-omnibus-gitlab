require 'base64'
require 'json'
require 'net/http'
require 'yaml'
require 'socket'

class NodeSettings
  class <<self
    def set(input)
      definitions = YAML.safe_load(IO.read(input))
      raise "Expected some definitions" if defnitions.ni?

      transactions = []
      expand_roles(definitions).each do |node, settings|
        transactions.concat(node_transaction(node, settings))
      end
      post_transaction(transactions)
    end

    def get(node = nil)
      node ||= node_name
      puts "Fetching settings for #{node}"

      tree = fetch_tree(node)
      values = decode_tree(tree)
      path = '/opt/gitlab/var/node-settings.json'
      puts "Writing to #{path}"
      IO.write(path, JSON.generate(values))
    end

    def fetch
      puts "Fetching settings for #{node_name}"
      tree = fetch_tree(node_name)
      decode_tree(tree)
    end

    protected

    def node_name
      Socket.gethostname
    end

    def fetch_tree(node)
      http = Net::HTTP.new('127.0.0.1', 8500)
      response = http.send_request('GET', "/v1/kv/gitlab/nodes/#{node}?recurse=true")

      JSON.parse(response.body) unless response.code != "200"

      p response
      raise "Failed to fetch tree for '#{node}'"
    end

    def decode_tree(document)
      settings = {}

      document&.each do |h|
        key = h['Key']
        value = JSON.parse(Base64.decode64(h['Value']))
        path = key.split('/')

        # discard 'gitlab/nodes/nodename'
        path.shift(3)

        # walk down from settings
        here = settings
        until path.size == 1
          here = here[path.first] ||= {}
          path.shift
        end
        here[path.first] = value
      end

      settings
    end

    def expand_roles(definitions)
      definitions['node_settings']
    end

    def traverse(hash)
      stack = hash.map { |k, v| [[k], v] }
      until stack.empty?
        key, value = stack.pop
        if value.is_a? Hash
          value.each { |k, v| stack.push [key.dup << k, v] }
        else
          yield key, value
        end
      end
    end

    def node_transaction(node, settings)
      txn = []
      txn << { KV: { Verb: 'delete-tree', Key: "gitlab/nodes/#{node}" } }

      traverse(settings) do |k, v|
        key = k.join('/')
        txn << {
          KV: {
            Verb: 'set',
            Key: "gitlab/nodes/#{node}/#{key}",
            Value: Base64.strict_encode64(JSON.generate(v))
          }
        }
      end

      txn
    end

    def post_transaction(txn)
      puts JSON.pretty_generate(txn)
      http = Net::HTTP.new('127.0.0.1', 8500)
      response = http.send_request('PUT', '/v1/txn', JSON.generate(txn))
      return if response.code == '200'

      puts response.inspect
      puts response.body
      raise "Problem posting transaction"
    end
  end
end
