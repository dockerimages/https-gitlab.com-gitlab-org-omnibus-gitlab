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

module Puma
  class << self
    def parse_variables
      return unless Services.enabled?('puma')

      parse_listen_address
    end

    def parse_listen_address
      return unless Gitlab['gitlab_workhorse']['auth_backend'].nil?

      https_url = puma_https_url

      # As described in https://gitlab.com/gitlab-org/gitlab/-/blob/master/workhorse/doc/operations/configuration.md#interaction-of-authbackend-and-authsocket,
      # Workhorse will give precedence to a UNIX socket. In order to ensure
      # traffic is sent over an encrypted channel, set auth_backend if SSL
      # has been enabled on Puma.
      if https_url
        Gitlab['gitlab_workhorse']['auth_backend'] = https_url
      else
        Gitlab['gitlab_workhorse']['auth_socket'] = puma_socket
      end
    end

    def workers(total_memory_kb = node_memory)
      [
        2, # Two is the minimum or web editor will no longer work.
        num_workers_by_resource_limits(total_memory_kb)
      ].max # max because we need at least 2 workers
    end

    # See how many worker processes fit in the system.
    # We scale this heuristically based on both the number of available cores
    # and the available node memory. There is a built-in assumption that
    # Puma workers consume roughly 1GB of memory. If this should change
    # significantly over time, we may have to revise the factors used
    # accordingly.
    #
    # See https://docs.google.com/spreadsheets/d/1K_NmAOKkfyt_LF1GIkf52NxzwmB8quEi6ihWNVPdjww/
    # to compare which values this produces compared to the previous approach that used
    # static limits to tune worker count.
    def num_workers_by_resource_limits(total_memory_kb)
      total_mem_gb = total_memory_kb / 1024**2

      # Determine whether the system is bound by either CPU or memory.
      # We consider a system with less than 50% excess RAM compared
      # to core count to be memory-bound.
      mem_ratio = total_mem_gb / num_cores.to_f
      mem_bound = mem_ratio <= 1.5

      # If the limiting factor is the number of cores, not memory,
      # always scale based on core count.
      return num_cores unless mem_bound

      # We might be tight on memory (a Puma worker uses north of 1GB).
      # For smaller amounts of RAM, we correct for a fixed amount.
      # For larger amounts of RAM, we expand into it for better utilization.
      mem_bound_workers =
        if total_mem_gb <= 8
          total_mem_gb - 2
        else
          (num_cores * mem_ratio * 0.9)
        end.to_i

      # min because we never want more workers than cores
      [num_cores, mem_bound_workers].min
    end

    private

    def num_cores
      Gitlab['node']['cpu']['total'].to_i
    end

    def node_memory
      Gitlab['node']['memory']['total'].to_i
    end

    def puma_socket
      attributes['socket'] || Gitlab['node']['gitlab']['puma']['socket']
    end

    def puma_https_url
      url(host: attributes['ssl_listen'], port: attributes['ssl_port'], scheme: 'https') if attributes['ssl_listen'] && attributes['ssl_port']
    end

    def attributes
      Gitlab['puma']
    end

    def url(host:, port:, scheme:)
      Addressable::URI.new(host: host, port: port, scheme: scheme).to_s
    end
  end
end
