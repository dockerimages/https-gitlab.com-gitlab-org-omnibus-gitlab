default['spamcheck']['enable'] = false
default['spamcheck']['dir'] = '/var/opt/gitlab/spamcheck'
default['spamcheck']['host'] = '127.0.0.1'
default['spamcheck']['port'] = 8001
default['spamcheck']['log_level'] = 'info'
default['spamcheck']['log_format'] = 'json'
default['spamcheck']['log_output'] = 'stdout'
default['spamcheck']['allowlist'] = {}
default['spamcheck']['denylist'] = {}
default['spamcheck']['allowed_domains'] = ['gitlab.com']
default['spamcheck']['log_directory'] = '/var/log/gitlab/spamcheck'
default['spamcheck']['env_directory'] = '/opt/gitlab/etc/spamcheck/env'
default['spamcheck']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
}

