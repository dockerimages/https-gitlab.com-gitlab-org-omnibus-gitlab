class GitlabConfig
  class << self
    def roles
      [
        {
          name: 'application',
          class: 'ApplicationRole'
        },
        {
          name: 'redis_sentinel',
          class: 'RedisSentinelRole'
        },
        {
          name: 'redis_master',
          class: 'RedisMasterRole'
        },
        {
          name: 'redis_slave'
        },
        {
          name: 'geo_primary',
          class: 'GeoPrimaryRole',
          proprerties: {
            manage_services: false
          }
        },
        {
          name: 'geo_secondary',
          class: 'GeoSecondaryRole',
          properties: {
            manage_services: false
          }
        },
        {
          name: 'monitoring',
          class: 'MonitoringRole'
        },
        {
          name: 'postgres',
          class: 'PostgresRole'
        },
        {
          name: 'pgbouncer',
          class: 'PgbouncerRole'
        },
        {
          name: 'consul',
          class: 'ConsulRole'
        }
      ]
    end

    def node_attributes
      [
        {
          name: 'package',
          class: 'Package'
        },
        {
          name: 'registry',
          class: 'Registry',
          properties: {
            priority: 20
          }
        },
        {
          name: 'redis',
          class: 'Redis',
          properties: {
            priority: 20
          }
        },
        {
          name: 'postgresql',
          class: 'Postgresql',
          properties: {
            priority: 20
          }
        },
        {
          name: 'repmgr',
        },
        {
          name: 'repmgrd',
        },
        {
          name: 'consul',
        },
        {
          name: 'gitaly',
          class: 'Gitaly',
        },
        {
          name: 'praefect',
          class: 'Praefect',
        },
        {
          name: 'mattermost',
          class: 'GitlabMattermost',
          properties: {
            priority: 30
          }
        },
        {
          name: 'letsencrypt',
          class: 'LetsEncrypt',
          properties: {
            priorty: 17
          }
        },
        {
          name: 'crond'
        }
      ]
    end

    def nested_attributes
      output = []
      attribute_blocks.each { |ab| output << { name: ab, attributes: get_attribute_block(ab) } }

      output
    end

    def attribute_blocks
      %w[
        monitoring
        gitlab
      ]
    end

    def get_attribute_block(name)
      send("#{name}_attributes")
    end

    def monitoring_attributes
      [
        {
          name: 'prometheus',
          class: 'Prometheus',
          properties: {
            priority: 20
          }
        },
        {
          name: 'grafana',
          class: 'Grafana',
          properties: {
            priority: 30
          }
        },
        {
          name: 'alertmanager',
          properties: {
            priority: 30
          }
        },
        {
          name: 'node_exporter',
          properties: {
            priority: 30
          }
        },
        {
          name: 'redis_exporter',
          properties: {
            priority: 30
          }
        },
        {
          name: 'postgres_exporter',
          properties: {
            priority: 30
          }
        },
        {
          name: 'gitlab_exporter',
          class: 'GitlabExporter',
          properties: {
            priority: 30
          }
        },
        {
          name: 'gitlab_monitor',
          properties: {
            priority: 30
          }
        },
      ]
    end

    def gitlab_attributes
      [
        {
          name: 'sidekiq_cluster',
          class: 'SidekiqCluster',
          properties: {
            priority: 20,
          },
          ee_attribute: true
        },
        {
          name: 'geo_postgresql',
          class: 'GeoPostgresql',
          properties: {
            priority: 20,
          },
          ee_attribute: true
        },
        {
          name: 'geo_secondary',
          ee_attribute: true
        },
        {
          name: 'geo_logcursor',
          ee_attribute: true
        },
        {
          name: 'sentinel',
          class: 'Sentinel',
          ee_attribute: true
        },
        {
          name: 'gitlab_shell',
          class: 'GitlabShell',
          properties: {
            priority: 10,
          }
        },
        {
          name: 'gitlab_rails',
          class: 'GitlabRails',
          properties: {
            priority: 15,
          }
        },
        {
          name: 'gitlab_workhorse',
          class: 'GitlabWorkhorse',
          properties: {
            priority: 20,
          }
        },
        {
          name: 'logging',
          class: 'Logging',
          properties: {
            priority: 20,
          }
        },
        {
          name: 'unicorn',
          class: 'Unicorn',
          properties: {
            priority: 20,
          }
        },
        {
          name: 'puma',
          class: 'Puma',
          properties: {
            priority: 20,
          }
        },
        {
          name: 'mailroom',
          class: 'IncomingEmail',
          properties: {
            priority: 20,
          }
        },
        {
          name: 'gitlab_pages',
          class: 'GitlabPages',
          properties: {
            priority: 20,
          }
        },
        {
          name: 'storage_check',
          class: 'StorageCheck',
          properties: {
            priority: 30,
          }
        },
        {
          name: 'nginx',
          class: 'Nginx',
          properties: {
            priority: 40,
          }
        },
        {
          name: 'external_url',
          properties: {
            default: nil
          }
        },
        {
          name: 'registry_external_url',
          properties: {
            default: nil
          }
        },
        {
          name: 'mattermost_external_url',
          properties: {
            default: nil
          }
        },
        {
          name: 'pages_external_url',
          properties: {
            default: nil
          }
        },
        {
          name: 'runtime_dir',
          properties: {
            default: nil
          }
        },
        {
          name: 'git_data_dir',
          properties: {
            default: nil
          }
        },
        {
          name: 'bootstrap',
        },
        {
          name: 'omnibus_gitconfig',
        },
        {
          name: 'manage_accounts',
        },
        {
          name: 'manage_storage_directories',
        },
        {
          name: 'user',
        },
        {
          name: 'gitlab_ci',
        },
        {
          name: 'sidekiq',
        },
        {
          name: 'mattermost_nginx',
        },
        {
          name: 'pages_nginx',
        },
        {
          name: 'registry_nginx',
        },
        {
          name: 'remote_syslog',
        },
        {
          name: 'logrotate',
        },
        {
          name: 'high_availability',
        },
        {
          name: 'web_server',
        },
        {
          name: 'prometheus_monitoring',
        },
        {
          name: 'pgbouncer',
        },
        {
          name: 'pgbouncer_exporter',
        }
      ]
    end
  end
end
