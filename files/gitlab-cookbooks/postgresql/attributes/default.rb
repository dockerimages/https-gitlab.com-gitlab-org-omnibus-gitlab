default['postgresql']['enable'] = true
default['postgresql']['ha'] = false
default['postgresql']['dir'] = "/var/opt/gitlab/postgresql"
default['postgresql']['data_dir'] = "/var/opt/gitlab/postgresql/data"
default['postgresql']['log_directory'] = "/var/log/gitlab/postgresql"
default['postgresql']['unix_socket_directory'] = "/var/opt/gitlab/postgresql"
default['postgresql']['username'] = "gitlab-psql"
default['postgresql']['uid'] = nil
default['postgresql']['gid'] = nil
default['postgresql']['shell'] = "/bin/sh"
default['postgresql']['home'] = "/var/opt/gitlab/postgresql"
# Postgres User's Environment Path
# defaults to /opt/gitlab/embedded/bin:/opt/gitlab/bin/$PATH. The install-dir path is set at build time
default['postgresql']['user_path'] = "#{node['package']['install-dir']}/embedded/bin:#{node['package']['install-dir']}/bin:$PATH"
default['postgresql']['sql_user'] = "gitlab"
default['postgresql']['sql_user_password'] = nil
default['postgresql']['sql_mattermost_user'] = "gitlab_mattermost"
default['postgresql']['port'] = 5432
# Postgres allow multi listen_address, comma-separated values.
# If used, first address from the list will be use for connection
default['postgresql']['listen_address'] = nil
default['postgresql']['max_connections'] = 200
default['postgresql']['md5_auth_cidr_addresses'] = []
default['postgresql']['trust_auth_cidr_addresses'] = []
default['postgresql']['shmmax'] = node['kernel']['machine'] =~ /x86_64/ ? 17179869184 : 4294967295
default['postgresql']['shmall'] = node['kernel']['machine'] =~ /x86_64/ ? 4194304 : 1048575
default['postgresql']['semmsl'] = 250
default['postgresql']['semmns'] = 32000
default['postgresql']['semopm'] = 32
default['postgresql']['semmni'] = ((node['postgresql']['max_connections'].to_i / 16) + 250)

# Resolves CHEF-3889
default['postgresql']['shared_buffers'] = if (node['memory']['total'].to_i / 4) > ((node['postgresql']['shmmax'].to_i / 1024) - 2097152)
                                            # guard against setting shared_buffers > shmmax on hosts with installed RAM > 64GB
                                            # use 2GB less than shmmax as the default for these large memory machines
                                            "14336MB"
                                          else
                                            "#{(node['memory']['total'].to_i / 4) / 1024}MB"
                                          end

default['postgresql']['work_mem'] = "8MB"
default['postgresql']['maintenance_work_mem'] = "16MB"
default['postgresql']['effective_cache_size'] = "#{(node['memory']['total'].to_i / 2) / 1024}MB"
default['postgresql']['log_min_duration_statement'] = -1 # Disable slow query logging by default
default['postgresql']['checkpoint_segments'] = 10
default['postgresql']['min_wal_size'] = '80MB'
default['postgresql']['max_wal_size'] = '1GB'
default['postgresql']['checkpoint_timeout'] = "5min"
default['postgresql']['checkpoint_completion_target'] = 0.9
default['postgresql']['checkpoint_warning'] = "30s"
default['postgresql']['wal_buffers'] = "-1"
default['postgresql']['autovacuum'] = "on"
default['postgresql']['log_autovacuum_min_duration'] = "-1"
default['postgresql']['autovacuum_max_workers'] = "3"
default['postgresql']['autovacuum_naptime'] = "1min"
default['postgresql']['autovacuum_vacuum_threshold'] = "50"
default['postgresql']['autovacuum_analyze_threshold'] = "50"
default['postgresql']['autovacuum_vacuum_scale_factor'] = "0.02" # 10x lower than PG defaults
default['postgresql']['autovacuum_analyze_scale_factor'] = "0.01" # 10x lower than PG defaults
default['postgresql']['autovacuum_freeze_max_age'] = "200000000"
default['postgresql']['autovacuum_vacuum_cost_delay'] = "20ms"
default['postgresql']['autovacuum_vacuum_cost_limit'] = "-1"
default['postgresql']['statement_timeout'] = "0"
default['postgresql']['log_line_prefix'] = nil
default['postgresql']['track_activity_query_size'] = "1024"
default['postgresql']['shared_preload_libraries'] = nil
default['postgresql']['dynamic_shared_memory_type'] = nil
default['postgresql']['random_page_cost'] = 4.0
default['postgresql']['max_locks_per_transaction'] = 64
default['postgresql']['log_temp_files'] = -1
default['postgresql']['log_checkpoints'] = 'off'

# Replication settings
default['postgresql']['sql_replication_user'] = "gitlab_replicator"
default['postgresql']['wal_level'] = "minimal"
default['postgresql']['max_wal_senders'] = 0
default['postgresql']['wal_keep_segments'] = 10
default['postgresql']['hot_standby'] = "off"
default['postgresql']['max_standby_archive_delay'] = "30s"
default['postgresql']['max_standby_streaming_delay'] = "30s"
default['postgresql']['max_replication_slots'] = 0
default['postgresql']['synchronous_commit'] = 'on'
default['postgresql']['synchronous_standby_names'] = ''
default['postgresql']['hot_standby_feedback'] = 'off'

# Backup/Archive settings
default['postgresql']['archive_mode'] = "off"
default['postgresql']['archive_command'] = nil
default['postgresql']['archive_timeout'] = "60"
