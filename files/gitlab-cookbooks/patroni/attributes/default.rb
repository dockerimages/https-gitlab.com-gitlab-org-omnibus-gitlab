default['patroni']['enable'] = false
default['patroni']['config_directory'] = '/var/opt/gitlab/patroni'
default['patroni']['install_directory'] = '/opt/gitlab/embedded/bin'
default['patroni']['log_directory'] = '/var/log/gitlab/patroni'
default['patroni']['bind_interface'] = 'lo'

default['patroni']['consul']['check_interval'] = '10s'
default['patroni']['consul']['extra_checks']['master'] = []
default['patroni']['consul']['extra_checks']['replica'] = []

default['patroni']['users']['superuser']['username'] = 'gitlab_superuser'
default['patroni']['users']['superuser']['password'] = 'gitlabsuperuser'
default['patroni']['users']['superuser']['options'] = %w[createrole createdb]
default['patroni']['users']['replication']['username'] = 'gitlab_replicator'
default['patroni']['users']['replication']['password'] = 'replicator'
default['patroni']['users']['replication']['options'] = %w[replication]

default['patroni']['config']['scope'] = 'pg-ha-cluster'
default['patroni']['config']['name'] = node.name
default['patroni']['config']['restapi']['listen'] = '0.0.0.0:8009'
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
default['patroni']['config']['bootstrap']['initdb'] = [{ 'encoding' => 'UTF8' }, { 'locale' => 'C.UTF-8' }]
default['patroni']['config']['bootstrap']['pg_hba'] = [
  'host postgres gitlab-superuser 192.168.0.0/11 md5',
  'host all gitlab-superuser 192.168.0.0/11 md5',
  'host all gitlab-superuser 192.168.0.0/11 md5',
  'host all gitlab-superuser 127.0.0.1/32 md5',
  'host replication gitlab-replicator 127.0.0.1/32 md5',
  'host replication gitlab-replicator 192.168.0.0/11 md5',
]
