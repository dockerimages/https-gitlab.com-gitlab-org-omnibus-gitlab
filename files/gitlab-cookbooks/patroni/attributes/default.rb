default['patroni']['enable'] = false
default['patroni']['config_directory'] = '/var/opt/gitlab/patroni'
default['patroni']['install_directory'] = '/opt/gitlab/embedded/bin'
default['patroni']['log_directory'] = '/var/log/gitlab/patroni'
default['patroni']['private_ipaddress'] = nil
default['patroni']['master_on_initialization'] = true

default['patroni']['consul']['check_interval'] = '10s'
default['patroni']['consul']['extra_checks']['master'] = []
default['patroni']['consul']['extra_checks']['replica'] = []

default['patroni']['users']['superuser']['username'] = 'gitlab_superuser'
default['patroni']['users']['superuser']['password'] = 'gitlabsuperuser'
default['patroni']['users']['superuser']['options'] = %w[superuser]
default['patroni']['users']['replication']['username'] = 'gitlab_replicator'
default['patroni']['users']['replication']['password'] = 'replicator'
default['patroni']['users']['replication']['options'] = %w[replication]


default['patroni']['restapi']['port'] = '8009'
default['patroni']['restapi']['listen_ip'] = '0.0.0.0'

default['patroni']['config']['scope'] = 'pg-ha-cluster'
default['patroni']['config']['name'] = node.name
default['patroni']['config']['consul']['host'] = '127.0.0.1:8500'

default['patroni']['config']['bootstrap']['dcs']['ttl'] = 30
default['patroni']['config']['bootstrap']['dcs']['loop_wait'] = 10
default['patroni']['config']['bootstrap']['dcs']['retry_timeout'] = 10
default['patroni']['config']['bootstrap']['dcs']['maximum_lag_on_failover'] = 1_048_576
default['patroni']['config']['bootstrap']['dcs']['postgresql']['use_pg_rewind'] = true
default['patroni']['config']['bootstrap']['dcs']['postgresql']['use_slots'] = true
default['patroni']['config']['bootstrap']['dcs']['postgresql']['parameters']['wal_level'] = 'replica'
default['patroni']['config']['bootstrap']['dcs']['postgresql']['parameters']['hot_standby'] = 'on'
default['patroni']['config']['bootstrap']['dcs']['postgresql']['parameters']['wal_keep_segments'] = 8
default['patroni']['config']['bootstrap']['dcs']['postgresql']['parameters']['max_wal_senders'] = 5
default['patroni']['config']['bootstrap']['dcs']['postgresql']['parameters']['max_replication_slots'] = 5
default['patroni']['config']['bootstrap']['dcs']['postgresql']['parameters']['checkpoint_timeout'] = 30
