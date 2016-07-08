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
require_relative 'load_balancer.rb'

module HighAvailability
  class << self

    def parse_variables
      parse_roles
      parse_configuration
    end

    def roles
      %w( load_balancer database redis worker )
    end

    def parse_roles
      roles.each do |role_name|
        parse_role(role_name)
      end
    end

    def parse_role(role_name)
      role = Gitlab["#{role_name}_role"]
      return unless role

      nodes = role['nodes']
      return unless nodes

      parse_nodes(role_name, nodes)
    end

    def parse_nodes(role_name, nodes)
      nodes.each do |node|
        next unless node['hostname']

        if Gitlab['node']['hostname'] == node['hostname']
          Gitlab['high_availability']['node'] = {
            'role' => role_name,
            'hostname' => node['hostname'],
            'ip' => node['ip']
          }
        end
      end
    end

    def parse_configuration
      return unless Gitlab['high_availability'] && Gitlab['high_availability']['node']
      node = Gitlab['high_availability']['node']

      Worker.parse_variables(node)
      # Load balancer parsed last because each component needs to be parsed first
      LoadBalancer.parse_variables(node)
    end
  end
end
