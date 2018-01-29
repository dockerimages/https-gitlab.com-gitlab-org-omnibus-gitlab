require 'base64'
require 'json'
require 'net/http'
require 'yaml'
require 'socket'

class NodeSettings
  class <<self
    def set(input)
      definitions = YAML.safe_load(IO.read(input))
      if definitions.nil?
        raise "Expected some definitions"
      end

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

    protected

    def node_name
      Socket.gethostname
    end

    def fetch_tree(node)
      http = Net::HTTP.new('127.0.0.1', 8500)
      response = http.send_request('GET', "/v1/kv/gitlab/nodes/#{node}?recurse=true" )

      if response.code != "200"
        p response
        raise "oh no"
      end

      JSON.parse(response.body)
    end

    def decode_tree(document)
      settings = {}

      if document
        document.each do |h|
          key = h['Key']
          value = JSON.parse(Base64.decode64(h['Value']))
          path = key.split('/')

          # discard 'gitlab/nodes/nodename'
          path.shift(3)

          # walk down from settings
          here = settings
          until path.size == 1
            unless here[path.first]
              here[path.first] = {}
            end
            here = here[path.first]
            path.shift
          end
          here[path.first] = value
        end
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
      if response.code != '200'
        puts response.inspect
        puts response.body
        raise "oh dear"
      end
    end
  end
end
