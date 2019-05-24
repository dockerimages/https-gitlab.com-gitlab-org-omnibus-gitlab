
pg_helper = PgHelper.new(node)
patroni_helper = PatroniHelper.new(node)
account_helper = AccountHelper.new(node)
omnibus_helper = OmnibusHelper.new(node)

postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group

##
# Create SSL cert + key in the defined location. Paths are relative to node['postgresql']['data_dir']
##
ssl_cert_file = File.absolute_path(node['postgresql']['ssl_cert_file'], node['postgresql']['data_dir'])
ssl_key_file = File.absolute_path(node['postgresql']['ssl_key_file'], node['postgresql']['data_dir'])

file ssl_cert_file do
  content node['postgresql']['internal_certificate']
  owner postgresql_username
  group postgresql_group
  mode 0400
  sensitive true
  only_if { node['postgresql']['ssl'] == 'on' }
end

file ssl_key_file do
  content node['postgresql']['internal_key']
  owner postgresql_username
  group postgresql_group
  mode 0400
  sensitive true
  only_if { node['postgresql']['ssl'] == 'on' }
end

postgresql_config = File.join(node['postgresql']['data_dir'], "postgresql.conf")
postgresql_runtime_config = File.join(node['postgresql']['data_dir'], 'runtime.conf')
should_notify = omnibus_helper.should_notify?("postgresql")

template postgresql_config do
  source 'postgresql.conf.erb'
  owner postgresql_username
  mode '0644'
  helper(:pg_helper) { pg_helper }
  variables(node['postgresql'].to_hash)
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end

template postgresql_runtime_config do
  source 'postgresql-runtime.conf.erb'
  owner postgresql_username
  mode '0644'
  helper(:pg_helper) { pg_helper }
  variables(node['postgresql'].to_hash)
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end

pg_hba_config = File.join(node['postgresql']['data_dir'], "pg_hba.conf")

template pg_hba_config do
  source 'pg_hba.conf.erb'
  owner postgresql_username
  mode "0644"
  variables(lazy { node['postgresql'].to_hash })
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end

template File.join(node['postgresql']['data_dir'], 'pg_ident.conf') do
  owner postgresql_username
  mode "0644"
  variables(node['postgresql'].to_hash)
  notifies :run, 'ruby_block[reload postgresql]', :immediately if should_notify
  notifies :run, 'ruby_block[start postgresql]', :immediately if should_notify
end

ruby_block 'reload postgresql' do
  block do
    pg_helper.reload
  end
  retries 20
  action :nothing
end

ruby_block 'start postgresql' do
  block do
    pg_helper.start
  end
  retries 20
  action :nothing
end
