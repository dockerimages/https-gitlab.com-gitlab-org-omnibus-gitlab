
pg_helper = PgHelper.new(node)
patroni_helper = PatroniHelper.new(node)
account_helper = AccountHelper.new(node)

postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group

##
# Create SSL cert + key in the defined location. Paths are relative to node['gitlab']['postgresql']['data_dir']
##
ssl_cert_file = File.absolute_path(node['gitlab']['postgresql']['ssl_cert_file'], node['gitlab']['postgresql']['data_dir'])
ssl_key_file = File.absolute_path(node['gitlab']['postgresql']['ssl_key_file'], node['gitlab']['postgresql']['data_dir'])

file ssl_cert_file do
  content node['gitlab']['postgresql']['internal_certificate']
  owner postgresql_username
  group postgresql_group
  mode 0400
  sensitive true
  only_if { node['gitlab']['postgresql']['ssl'] == 'on' }
end

file ssl_key_file do
  content node['gitlab']['postgresql']['internal_key']
  owner postgresql_username
  group postgresql_group
  mode 0400
  sensitive true
  only_if { node['gitlab']['postgresql']['ssl'] == 'on' }
end

postgresql_config = if patroni_helper.is_running?
                      File.join(node['gitlab']['postgresql']['data_dir'], "postgresql.base.conf")
                    else
                      File.join(node['gitlab']['postgresql']['data_dir'], "postgresql.conf")
                    end
postgresql_runtime_config = File.join(node['gitlab']['postgresql']['data_dir'], 'runtime.conf')
should_notify = pg_helper.should_notify?

template postgresql_config do
  source 'postgresql.conf.erb'
  owner postgresql_username
  mode 0644
  helper(:pg_helper) { pg_helper }
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end

template postgresql_runtime_config do
  source 'postgresql-runtime.conf.erb'
  owner postgresql_username
  mode 0644
  helper(:pg_helper) { pg_helper }
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end

pg_hba_config = File.join(node['gitlab']['postgresql']['data_dir'], "pg_hba.conf")

template pg_hba_config do
  source 'pg_hba.conf.erb'
  owner postgresql_username
  mode 0644
  variables(lazy { node['gitlab']['postgresql'].to_hash })
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end

template File.join(node['gitlab']['postgresql']['data_dir'], 'pg_ident.conf') do
  owner postgresql_username
  mode 0644
  variables(node['gitlab']['postgresql'].to_hash)
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end
