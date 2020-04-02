require 'net/http'

module Patroni
  ClientError = Class.new(StandardError)

  class Client
    attr_accessor :uri

    def initialize
      attributes = GitlabCtl::Util.get_public_node_attributes
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
