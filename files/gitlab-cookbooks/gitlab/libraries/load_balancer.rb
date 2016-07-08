#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require_relative 'gitlab_rails.rb'
require_relative 'services.rb'

module LoadBalancer
  class << self

    def parse_variables(node)
      hostname = node['hostname']
      return unless hostname

      Services.isolated_run('haproxy')

      return unless Gitlab['load_balancer_role'][hostname]

      # If a user explicitly set load_balancer_role[HOSTNAME] settings
      # that means that they want to override the global settings for this node
      Gitlab['load_balancer_role'][hostname].each do |key, config|
        Gitlab['load_balancer_role'][key] = config
      end

      parse_worker_role_settings
    end

    def parse_worker_role_settings
      return unless Gitlab['worker_role']

      parse_backend
      parse_frontend
    end

    def parse_backend
      backend = [
        { 'balance' => 'roundrobin', 'option' => 'forwardfor', 'option' => 'httpchk GET /' }
      ]
      http_backend = backend
      http_backend << { 'mode' => 'http' }
      Gitlab['worker_role']['nodes'].each do |node|
        http_backend << { 'server' => "#{node['hostname']} #{node['ip']}:#{node['port']} check"}
      end

      ssh_backend = backend
      ssh_backend << { 'mode' => 'tcp', 'option' => 'tcplog' }
      Gitlab['worker_role']['nodes'].each do |node|
        ssh_backend << { 'server' => "#{node['hostname']} #{node['ip']}:22 check"}
      end

      Gitlab['load_balancer_role']['backend'] ||= {
        'ssh_backend' => ssh_backend,
        'http_backend' => http_backend
      }
      end
    end

    def parse_frontend
      # We will listen on all interfaces by default as we don't have
      # a way of knowing which interface is active
      Gitlab['load_balancer_role']['frontend'] ||= {
        "www" => [
          { "bind" => "*:#{Gitlab['gitlab_rails']['gitlab_port']}"}, { "mode" => "http" }, {"default_backend" => "backend"}
        ]
      }
    end
  end
end
