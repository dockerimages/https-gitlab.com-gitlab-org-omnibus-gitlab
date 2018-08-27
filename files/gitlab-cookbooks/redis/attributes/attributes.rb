####
# Redis
####
default['gitlab']['redis']['enable'] = false
default['gitlab']['redis']['ha'] = false
default['gitlab']['redis']['hz'] = 10
default['gitlab']['redis']['dir'] = "/var/opt/gitlab/redis"
default['gitlab']['redis']['log_directory'] = "/var/log/gitlab/redis"
default['gitlab']['redis']['username'] = "gitlab-redis"
default['gitlab']['redis']['group'] = "gitlab-redis"
default['gitlab']['redis']['uid'] = nil
default['gitlab']['redis']['gid'] = nil
default['gitlab']['redis']['shell'] = "/bin/false"
default['gitlab']['redis']['home'] = "/var/opt/gitlab/redis"
default['gitlab']['redis']['bind'] = '127.0.0.1'
default['gitlab']['redis']['port'] = 0
default['gitlab']['redis']['maxclients'] = "10000"
default['gitlab']['redis']['maxmemory'] = "0"
default['gitlab']['redis']['maxmemory_policy'] = "noeviction"
default['gitlab']['redis']['maxmemory_samples'] = 5
default['gitlab']['redis']['tcp_backlog'] = 511
default['gitlab']['redis']['tcp_timeout'] = 60
default['gitlab']['redis']['tcp_keepalive'] = 300
default['gitlab']['redis']['password'] = nil
default['gitlab']['redis']['unixsocket'] = "/var/opt/gitlab/redis/redis.socket"
default['gitlab']['redis']['unixsocketperm'] = "777"
default['gitlab']['redis']['master'] = true
default['gitlab']['redis']['master_name'] = 'gitlab-redis'
default['gitlab']['redis']['master_ip'] = nil
default['gitlab']['redis']['master_port'] = 6379
default['gitlab']['redis']['master_password'] = nil
default['gitlab']['redis']['client_output_buffer_limit_normal'] = "0 0 0"
default['gitlab']['redis']['client_output_buffer_limit_slave'] = "256mb 64mb 60"
default['gitlab']['redis']['client_output_buffer_limit_pubsub'] = "32mb 8mb 60"
default['gitlab']['redis']['save'] = ['900 1', '300 10', '60 10000']
