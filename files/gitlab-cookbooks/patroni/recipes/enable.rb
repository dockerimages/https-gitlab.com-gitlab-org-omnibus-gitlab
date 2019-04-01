
config_directory            = node['patroni']['config_directory']
install_directory           = node['patroni']['install_directory']
log_directory               = node['patroni']['log_directory']
postgresql_superuser        = node['patroni']['users']['superuser']['username']
patroni_config_path         = "#{config_directory}/patroni.yml"

Patroni::AttributesHelper.populate_missing_values(node)

account_helper = AccountHelper.new(node)

directory config_directory do
  recursive true
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
end

directory log_directory do
  recursive true
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
end

file patroni_config_path do
  content YAML.dump(node['patroni']['config'].to_hash)
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  notifies :reload, 'runit_service[patroni]', :delayed
end

execute 'update bootstrap config' do
  command <<-CMD
#{install_directory}/bin/patronictl -c #{patroni_config_path} edit-config --force --replace - <<-YML
#{YAML.dump(node['patroni']['config']['bootstrap']['dcs'].to_hash)}
YML
  CMD
  # patronictl edit-config fails (for some reason) if the state is not in a running state
  only_if "/opt/gitlab/embedded/bin/sv status patroni && #{install_directory}/bin/patronictl -c #{patroni_config_path} list | grep #{node.name} | grep running"
end

runit_service 'patroni' do
  supervisor_owner account_helper.postgresql_user
  supervisor_group account_helper.postgresql_group
  restart_on_update false
  control(['t'])
  options({
    log_directory: log_directory
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['patroni'].to_hash)
end

# template "#{node['postgresql']['config_directory']}/.pgpass" do
#   source 'pgpass.erb'
#   variables(
#     hostname: 'localhost',
#     port: postgresql_helper.postgresql_port,
#     database: '*',
#     username: postgresql_superuser,
#     password: node['patroni']['users']['superuser']['password']
#   )
#   owner account_helper.postgresql_user
#   group account_helper.postgresql_group
#   mode '0600'
# end
