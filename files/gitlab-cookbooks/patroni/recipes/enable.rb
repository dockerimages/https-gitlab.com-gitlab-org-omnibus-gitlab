
config_directory            = node['patroni']['config_directory']
install_directory           = node['patroni']['install_directory']
log_directory               = node['patroni']['log_directory']
postgresql_superuser        = node['patroni']['users']['superuser']['username']
patroni_config_path         = "#{config_directory}/patroni.yml"

Patroni::AttributesHelper.populate_missing_values(node)

account_helper = AccountHelper.new(node)
pg_helper = PgHelper.new(node)

[
  config_directory,
  log_directory
].each do |dir|
  directory dir do
    recursive true
    owner account_helper.postgresql_user
    group account_helper.postgresql_group
  end
end

file patroni_config_path do
  content YAML.dump(node['patroni']['config'].to_hash)
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  notifies :reload, 'runit_service[patroni]', :delayed
end

gitlab_super_user = node['gitlab']['postgresql']['super_user']
gitlab_super_user_password = node['gitlab']['postgresql']['super_user_password']

postgresql_user gitlab_super_user do
  password "md5#{gitlab_super_user_password}" unless gitlab_super_user_password.nil?
  action :create
  options %w(superuser)
  not_if { pg_helper.is_slave? }
end

if node["gitlab"]["postgresql"]["enable"]
  # Disable postgresql runit service so that patroni can take over
  include_recipe "postgresql::disable"
end

runit_service 'patroni' do
  supervisor_owner account_helper.postgresql_user
  supervisor_group account_helper.postgresql_group
  restart_on_update false
  control(['t'])
  options({
    user: account_helper.postgresql_user,
    groupname: account_helper.postgresql_group,
    log_directory: log_directory
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['patroni'].to_hash)
end

execute 'update bootstrap config' do
  command <<-CMD
#{install_directory}/patronictl -c #{patroni_config_path} edit-config --force --replace - <<-YML
#{YAML.dump(node['patroni']['config']['bootstrap']['dcs'].to_hash)}
YML
  CMD
  # patronictl edit-config fails (for some reason) if the state is not in a running state
  only_if "/opt/gitlab/embedded/bin/sv status patroni && #{install_directory}/patronictl -c #{patroni_config_path} list | grep #{node.name} | grep running"
end
