require 'tomlib'

module Praefect
  class << self
    def parse_variables
      parse_virtual_storages

      remap_legacy_values
    end

    # remap_legacy_values moves configuration values from their legacy locations to where they are
    # in Praefect's own configuration. All of the configuration was previously grouped under Gitlab['praefect']
    # but now Praefect's own config is under Gitlab['praefect']['configuration']. This then allows us to
    # simply encode the map as TOML to get the resulting Praefect configuration file without having to manually
    # template every key. As existing configuration files may can still have the configuration in its old place,
    # this method provides backwards compatibility by moving the old values to their new locations. This can
    # compatibility wrapper can be removed in 16.0
    def remap_legacy_values
      Gitlab['praefect']['configuration'] = {} unless Gitlab['praefect']['configuration']
      # This mapping is (new_key => old_key). The value from the old location gets written to it's new location.
      # If the new_key is string, the old value is directly written to it. If it is a hash map, the structure
      # is walked down and appropriately until the leaf key is reached.
      remap_recursive(
        {
          'listen_addr' => 'listen_addr',
          'socket_path' => 'socket_path',
          'prometheus_listen_addr' => 'prometheus_listen_addr',
          'tls_listen_addr' => 'tls_listen_addr',
          'prometheus_exclude_database_from_default_metrics' => 'separate_database_metrics',
          'auth' => {
            'token' => 'auth_token',
            'transitioning' => 'auth_transitioning',
          },
          'logging' => {
            'format' => 'logging_format',
            'level' => 'logging_level',
          },
          'failover' => {
            'enabled' => 'failover_enabled',
          },
          'background_verification' => {
            'delete_invalid_records' => 'background_verification_delete_invalid_records',
            'verification_interval' => 'background_verification_verification_interval',
          },
          'reconciliation' => {
            'scheduling_interval' => 'reconciliation_scheduling_interval',
            'histogram_buckets' => 'reconciliation_histogram_buckets',
          },
          'tls' => {
            'certificate_path' => 'certificate_path',
            'key_path' => 'key_path',
          },
          'database' => {
            'host' => 'database_host',
            'port' => 'database_port',
            'user' => 'database_user',
            'password' => 'database_password',
            'dbname' => 'database_dbname',
            'sslmode' => 'database_sslmode',
            'sslcert' => 'database_sslcert',
            'sslkey' => 'database_sslkey',
            'sslrootcert' => 'database_sslrootcert',
            'session_pooled' => {
              'host' => 'database_direct_host',
              'port' => 'database_direct_port',
              'user' => 'database_direct_user',
              'password' => 'database_direct_password',
              'dbname' => 'database_direct_dbname',
              'sslmode' => 'database_direct_sslmode',
              'sslcert' => 'database_direct_sslcert',
              'sslkey' => 'database_direct_sslkey',
              'sslrootcert' => 'database_direct_sslrootcert',
            }
          },
          'sentry' => {
            'sentry_dsn' => 'sentry_dsn',
            'sentry_environment' => 'sentry_environment',
          },
          'prometheus' => {
            'grpc_latency_buckets' => 'prometheus_grpc_latency_buckets',
          },
          'graceful_stop_timeout' => 'graceful_stop_timeout'
        },
        Gitlab['praefect']['configuration']
      )

      return unless Gitlab['praefect']['virtual_storages']

      # Migrate the virtual storage configuration separately as it doesn't match the structure of the rest of the config.
      Gitlab['praefect']['configuration']['virtual_storage'] = [] unless Gitlab['praefect']['configuration']['virtual_storage']
      Gitlab['praefect']['virtual_storages'].each do |name, details|
        virtual_storage = {
          'name' => name,
          'node' => [],
        }

        virtual_storage['default_replication_factor'] = details['default_replication_factor'] if details['default_replication_factor']

        details['nodes'].each do |name, details|
          virtual_storage['node'].append(
            {
              'storage' => name,
              'address' => details['address'],
              'token' => details['token'],
            }
          )
        end

        Gitlab['praefect']['configuration']['virtual_storage'].append(virtual_storage)
      end
    end

    # remap_recursive does the recursive part of the key mapping. mappings and new_configuration are both at the
    # same level of the config tree. mappings contains the keys that should be written to in the new_configuration.
    def remap_recursive(mappings, new_configuration)
      mappings.each do |new_key, old_key|
        # If this is a hash, recurse the tree to create the correct structure.
        if old_key.is_a?(Hash)
          new_configuration[new_key] = {} unless new_configuration[new_key]
          remap_recursive(mappings[new_key], new_configuration[new_key])
          next
        end

        # If new_key is a string, it's a leaf and we should write the old value there.
        new_configuration[new_key] = Gitlab['praefect'][old_key]
      end
    end

    def parse_virtual_storages
      return if Gitlab['praefect']['virtual_storages'].nil?

      raise "Praefect virtual_storages must be a hash" unless Gitlab['praefect']['virtual_storages'].is_a?(Hash)

      Gitlab['praefect']['virtual_storages'].each do |virtual_storage, config_keys|
        next unless config_keys.key?('nodes')

        raise "Nodes of Praefect virtual storage `#{virtual_storage}` must be a hash" unless config_keys['nodes'].is_a?(Hash)
      end
    end
  end
end
