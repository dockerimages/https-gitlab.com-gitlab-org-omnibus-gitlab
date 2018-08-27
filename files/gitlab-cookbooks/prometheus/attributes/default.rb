####
# Prometheus server
####

default['gitlab']['prometheus']['enable'] = false
default['gitlab']['prometheus']['monitor_kubernetes'] = true
default['gitlab']['prometheus']['username'] = 'gitlab-prometheus'
default['gitlab']['prometheus']['uid'] = nil
default['gitlab']['prometheus']['gid'] = nil
default['gitlab']['prometheus']['shell'] = '/bin/sh'
default['gitlab']['prometheus']['home'] = '/var/opt/gitlab/prometheus'
default['gitlab']['prometheus']['log_directory'] = '/var/log/gitlab/prometheus'
default['gitlab']['prometheus']['remote_read'] = []
default['gitlab']['prometheus']['remote_write'] = []
default['gitlab']['prometheus']['rules_directory'] = "#{node['gitlab']['prometheus']['home']}/rules"
default['gitlab']['prometheus']['scrape_interval'] = 15
default['gitlab']['prometheus']['scrape_timeout'] = 15
default['gitlab']['prometheus']['scrape_configs'] = []
default['gitlab']['prometheus']['listen_address'] = 'localhost:9090'
default['gitlab']['prometheus']['chunk_encoding_version'] = 2
default['gitlab']['prometheus']['target_heap_size'] = (
  # Use 25mb + 2% of total memory for Prometheus memory.
  26_214_400 + (node['memory']['total'].to_i * 1024 * 0.02)
).to_i

####
# Prometheus Alertmanager
####

default['gitlab']['alertmanager']['enable'] = false
default['gitlab']['alertmanager']['home'] = '/var/opt/gitlab/alertmanager'
default['gitlab']['alertmanager']['log_directory'] = '/var/log/gitlab/alertmanager'
default['gitlab']['alertmanager']['listen_address'] = 'localhost:9093'
default['gitlab']['alertmanager']['admin_email'] = nil
default['gitlab']['alertmanager']['inhibit_rules'] = []
default['gitlab']['alertmanager']['receivers'] = []
default['gitlab']['alertmanager']['routes'] = []
default['gitlab']['alertmanager']['templates'] = []

####
# Prometheus Node Exporter
####
default['gitlab']['node-exporter']['enable'] = false
default['gitlab']['node-exporter']['home'] = '/var/opt/gitlab/node-exporter'
default['gitlab']['node-exporter']['log_directory'] = '/var/log/gitlab/node-exporter'
default['gitlab']['node-exporter']['listen_address'] = 'localhost:9100'

####
# Redis exporter
###
default['gitlab']['redis-exporter']['enable'] = false
default['gitlab']['redis-exporter']['log_directory'] = "/var/log/gitlab/redis-exporter"
default['gitlab']['redis-exporter']['listen_address'] = 'localhost:9121'

####
# Postgres exporter
###
default['gitlab']['postgres-exporter']['enable'] = false
default['gitlab']['postgres-exporter']['home'] = '/var/opt/gitlab/postgres-exporter'
default['gitlab']['postgres-exporter']['log_directory'] = "/var/log/gitlab/postgres-exporter"
default['gitlab']['postgres-exporter']['listen_address'] = 'localhost:9187'

####
# Gitlab monitor
###
default['gitlab']['gitlab-monitor']['enable'] = false
default['gitlab']['gitlab-monitor']['log_directory'] = "/var/log/gitlab/gitlab-monitor"
default['gitlab']['gitlab-monitor']['home'] = "/var/opt/gitlab/gitlab-monitor"
default['gitlab']['gitlab-monitor']['listen_address'] = 'localhost'
default['gitlab']['gitlab-monitor']['listen_port'] = '9168'

# To completely disable prometheus, and all of it's exporters, set to false
default['gitlab']['prometheus-monitoring']['enable'] = true

####
# Storage check
####
default['gitlab']['storage-check']['enable'] = false
default['gitlab']['storage-check']['target'] = nil
default['gitlab']['storage-check']['log_directory'] = '/var/log/gitlab/storage-check'
