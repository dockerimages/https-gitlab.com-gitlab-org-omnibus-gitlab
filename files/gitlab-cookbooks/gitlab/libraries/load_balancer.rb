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

module LoadBalancer
  class << self

    def parse_variables(node)
      hostname = node['hostname']
      return unless hostname

      Gitlab['haproxy']['enable'] = true

      return unless Gitlab['load_balancer_role'][hostname]

      # If a user explicitly set load_balancer_role[HOSTNAME] settings
      # that means that they want to override the global settings for this node
      Gitlab['load_balancer_role'][hostname].each do |key, config|
        Gitlab['load_balancer_role'][key] = config
      end

      # return unless Gitlab['high_availability']["worker_role"]
      # backend = []
      # Gitlab['high_availability']["worker_role"]['nodes'].each do |node|
      #   backend << { 'server' => "#{node['hostname']} #{node['ip']}:#{node['port']} check"}
      # end
      #
      # if backend.any?
      #   Gitlab['haproxy']['backend'] = { 'backend' => backend }
      # end

    end
  end
end
