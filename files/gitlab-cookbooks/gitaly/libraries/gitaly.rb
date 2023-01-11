#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require 'chef/mash'
require_relative '../../package/libraries/helpers/output_helper.rb'

module Gitaly
  class << self
    include OutputHelper

    def parse_variables
      parse_git_data_dirs
      parse_gitaly_storages
      parse_gitconfig
      parse_legacy_cgroup_variables

      remap_legacy_values
    end

    def parse_legacy_cgroup_variables
      # maintain backwards compatibility with pre 15.0 Gitaly cgroups config
      cgroups_repositories_memory_bytes = Gitlab['gitaly']['cgroups_repositories_memory_bytes'] || (Gitlab['gitaly']['cgroups_memory_limit'] if Gitlab['gitaly']['cgroups_memory_enabled'])
      cgroups_repositories_cpu_shares = Gitlab['gitaly']['cgroups_repositories_cpu_shares'] || (Gitlab['gitaly']['cgroups_cpu_shares'] if Gitlab['gitaly']['cgroups_cpu_enabled'])
      cgroups_repositories_count = Gitlab['gitaly']['cgroups_repositories_count'] || Gitlab['gitaly']['cgroups_count']
      cgroups_cpu_shares = Gitlab['gitaly']['cgroups_cpu_shares'] if Gitlab['gitaly']['cgroups_repositories_count'] && cgroups_repositories_count&.positive?

      Gitlab['gitaly']['cgroups_cpu_shares'] = cgroups_cpu_shares
      Gitlab['gitaly']['cgroups_repositories_count'] = cgroups_repositories_count
      Gitlab['gitaly']['cgroups_repositories_memory_bytes'] = cgroups_repositories_memory_bytes
      Gitlab['gitaly']['cgroups_repositories_cpu_shares'] = cgroups_repositories_cpu_shares
    end

    def gitaly_address
      socket_path = user_config.dig('configuration', 'socket_path')         || user_config['socket_path']     || package_default.dig('configuration', 'socket_path')
      listen_addr = user_config.dig('configuration', 'listen_addr')         || user_config['listen_addr']     || package_default.dig('configuration', 'listen_addr')
      tls_listen_addr = user_config.dig('configuration', 'tls_listen_addr') || user_config['tls_listen_addr'] || package_default.dig('configuration', 'tls_listen_addr')

      # Default to using socket path if available
      if tls_listen_addr && !tls_listen_addr.empty?
        "tls://#{tls_listen_addr}"
      elsif socket_path && !socket_path.empty?
        "unix:#{socket_path}"
      elsif listen_addr && !listen_addr.empty?
        "tcp://#{listen_addr}"
      end
    end

    def parse_git_data_dirs
      Gitlab['git_data_dirs'] = { "default" => { "path" => "/var/opt/gitlab/git-data" } } if Gitlab['git_data_dirs'].empty?

      Gitlab['git_data_dirs'].map do |name, details|
        Gitlab['git_data_dirs'][name]['path'] = details[:path] || details['path'] || '/var/opt/gitlab/git-data'
      end

      Gitlab['gitlab_rails']['repositories_storages'] =
        Hash[Mash.new(Gitlab['git_data_dirs']).map do |name, data_directory|
          shard_gitaly_address = data_directory['gitaly_address'] || gitaly_address

          defaults = { 'path' => File.join(data_directory['path'], 'repositories'), 'gitaly_address' => shard_gitaly_address }
          params = data_directory.merge(defaults)

          [name, params]
        end]
    end

    def parse_gitaly_storages
      return unless Gitlab['gitaly']['storage'].nil?

      storages = []
      Gitlab['gitlab_rails']['repositories_storages'].each do |key, value|
        storages << {
          'name' => key,
          'path' => value['path']
        }
      end
      Gitlab['gitaly']['storage'] = storages
    end

    # Compute the default gitconfig from the old Omnibus gitconfig setting.
    # This depends on the Gitlab cookbook having been parsed already.
    def parse_gitconfig
      # If the administrator has set `gitaly['gitconfig']` then we do not add a
      # fallback gitconfig.
      return unless Gitlab['gitaly']['gitconfig'].nil?

      # Furthermore, if the administrator has not overridden the
      # `omnibus_gitconfig` we do not have to migrate anything either. Most
      # importantly, we are _not_ interested in migrating defaults.
      return if Gitlab['omnibus_gitconfig']['system'].nil?

      # We use the old system-level Omnibus gitconfig as the default value...
      omnibus_gitconfig = Gitlab['omnibus_gitconfig']['system'].flat_map do |section, entries|
        entries.map do |entry|
          key, value = entry.split('=', 2)

          raise "Invalid entry detected in omnibus_gitconfig['system']: '#{entry}' should be in the form key=value" if key.nil? || value.nil?

          "#{section}.#{key.rstrip}=#{value.lstrip}"
        end
      end

      # ... but remove any of its values that are part of the default
      # configuration. We do not want to inject our old default values into
      # Gitaly anymore given that it is setting its own defaults nowadays.
      # Furthermore, we must not inject the `core.fsyncObjectFiles` config
      # entry, which has been deprecated in Git.
      omnibus_gitconfig -= Gitlab['node']['gitlab']['omnibus-gitconfig']['system'].flat_map do |section, entries|
        entries.map do |entry|
          key, value = entry.split('=', 2)
          "#{section}.#{key.rstrip}=#{value.lstrip}"
        end
      end

      # The configuration format has changed. Previously, we had a map of
      # top-level config entry keys to their sublevel entry keys which also
      # included a value. The new format is an array of hashes with key and
      # value entries.
      gitaly_gitconfig = omnibus_gitconfig.map do |config|
        # Split up the `foo.bar=value` to obtain the left-hand and right-hand sides of the assignment
        section_subsection_and_key, value = config.split('=', 2)

        # We need to split up the left-hand side. This can either be of the
        # form `core.gc`, or of the form `http "http://example.com".insteadOf`.
        # We thus split from the right side at the first dot we see.
        key, section_and_subsection = section_subsection_and_key.reverse.split('.', 2)
        key.reverse!

        # And then we need to potentially split the section/subsection if we
        # have `http "http://example.com"` now.
        section, subsection = section_and_subsection.reverse!.split(' ', 2)
        subsection&.gsub!(/\A"|"\Z/, '')

        # So that we have finally split up the section, subsection, key and
        # value. It is fine for the `subsection` to be `nil` here in case there
        # is none.
        { 'section' => section, 'subsection' => subsection, 'key' => key, 'value' => value }
      end

      return unless gitaly_gitconfig.any?

      Gitlab['gitaly']['gitconfig'] = gitaly_gitconfig
    end

    private

    def user_config
      Gitlab['gitaly']
    end

    def package_default
      Gitlab['node']['gitaly'].to_hash
    end

    # remap_legacy_values moves configuration values from their legacy locations to where they are
    # in Gitaly's own configuration. All of the configuration was previously grouped under Gitlab['gitaly']
    # but now Gitaly's own config is under Gitlab['gitaly']['configuration']. This then allows us to
    # simply encode the map as TOML to get the resulting Gitaly configuration file without having to manually
    # template every key. As existing configuration files may can still have the configuration in its old place,
    # this method provides backwards compatibility by moving the old values to their new locations. This can
    # compatibility wrapper can be removed in 16.0
    def remap_legacy_values
      Gitlab['gitaly']['configuration'] = {} unless Gitlab['gitaly']['configuration']

      # This mapping is (new_key => old_key). The value from the old location gets written to it's new location.
      # If the new_key is string, the old value is directly written to it. If it is a hash map, the structure
      # is walked down and appropriately until the leaf key is reached. If it is a function, it will be executed
      # and it should return the value for the new key.
      remap_recursive(
        {
          'socket_path' => 'socket_path',
          'runtime_dir' => 'runtime_dir',
          'listen_addr' => 'listen_addr',
          'prometheus_listen_addr' => 'prometheus_listen_addr',
          'tls_listen_addr' => 'tls_listen_addr',
          'tls' => {
            'certificate_path' => 'certificate_path',
            'key_path' => 'key_path'
          },
          'graceful_restart_timeout' => 'graceful_restart_timeout',
          'logging' => {
            'level' => 'logging_level',
            'format' => 'logging_format',
            'sentry_dsn' => 'logging_sentry_dsn',
            'ruby_sentry_dsn' => 'logging_ruby_sentry_dsn',
            'sentry_environment' => 'logging_sentry_environment',
            'dir' => 'log_directory'
          },
          'prometheus' => {
            'grpc_latency_buckets' => 'prometheus_grpc_latency_buckets'
          },
          'auth' => {
            'token' => 'auth_token',
            'transitioning' => 'auth_transitioning'
          },
          'git' => {
            'catfile_cache_size' => 'git_catfile_cache_size',
            'bin_path' => 'git_bin_path',
            'use_bundled_binaries' => 'user_bundled_git',
            'signing_key' => 'gpg_signing_key_path',
            'config' => lambda {
              return [] unless Gitlab['gitaly']['gitconfig']

              Gitlab['gitaly']['gitconfig'].map do |entry|
                {
                  'key' => [entry['section'], entry['subsection'], entry['key']].compact.join('.'),
                  'value' => entry['value']
                }
              end
            }
          },
          'gitaly-ruby' => {
            'max_rss' => 'ruby_max_rss',
            'graceful_restart_timeout' => 'ruby_graceful_restart_timeout',
            'restart_delay' => 'ruby_restart_delay',
            'num_workers' => 'ruby_num_workers'
          },
          'storage' => 'storage',
          'hooks' => {
            'custom_hooks_dir' => 'custom_hooks_dir'
          },
          'daily_maintenance' => {
            'disabled' => 'daily_maintenance_disabled',
            'start_hour' => 'daily_maintenance_start_hour',
            'start_minute' => 'daily_maintenance_start_minute',
            'duration' => 'daily_maintenance_duration',
            'storages' => 'daily_maintenance_storages'
          },
          'cgroups' => {
            'mountpoint' => 'cgroups_mountpoint',
            'hierarchy_root' => 'cgroups_hierarchy_root',
            'memory_bytes' => 'cgroups_memory_bytes',
            'cpu_shares' => 'cgroups_cpu_shares',
            'repositories' => {
              'count' => 'cgroups_repositories_count',
              'memory_bytes' => 'cgroups_repositories_memory_bytes',
              'cpu_shares' => 'cgroups_repositories_cpu_shares'
            }
          },
          'concurrency' => 'concurrency',
          'rate_limiting' => 'rate_limiting',
          'pack_objects_cache' => {
            'enabled' => 'pack_objects_cache_enabled',
            'dir' => 'pack_objects_cache_dir',
            'max_age' => 'pack_objects_cache_max_age'
          }
        },
        Gitlab['gitaly']['configuration']
      )
    end

    # remap_recursive does the recursive part of the key mapping. mappings and new_configuration are both at the
    # same level of the config tree. mappings contains the keys that should be written to in the new_configuration.
    def remap_recursive(mappings, new_configuration)
      mappings.each do |new_key, mapping|
        # If mapping is a hash, it denotes a subsection in the configuration. Traverse the hash and
        # handle each key there and place them in the subsection.
        if mapping.is_a?(Hash)
          new_configuration[new_key] = {} unless new_configuration[new_key]
          remap_recursive(mappings[new_key], new_configuration[new_key])
          next
        end

        # If mapping is a String, it's the old key. The value will be copied from the old key as is to the new key.
        if mapping.is_a?(String)
          new_configuration[new_key] = Gitlab['gitaly'][mapping]
          next
        end

        # Otherwise the mapping is a function that returns the value for the new key.
        new_configuration[new_key] = mapping.call
      end
    end
  end
end
