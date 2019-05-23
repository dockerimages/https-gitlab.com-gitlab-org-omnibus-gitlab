
config_directory            = node['patroni']['config_directory']
install_directory           = node['patroni']['install_directory']
log_directory               = node['patroni']['log_directory']
patroni_config_path         = "#{config_directory}/patroni.yml"

Patroni::AttributesHelper.populate_missing_values(node)

account_helper = AccountHelper.new(node)
pg_helper = PgHelper.new(node)
patroni_helper = PatroniHelper.new(node)

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

superuser = node['patroni']['users']['superuser']['username']
superuser_password = node['patroni']['users']['superuser']['password']
superuser_options = node['patroni']['users']['superuser']['options']

postgresql_user superuser do
  password superuser_password.to_s unless superuser_password.nil?
  action :create
  options superuser_options
  not_if { pg_helper.is_slave? }
end

if node["gitlab"]["postgresql"]["enable"]
  # Disable postgresql runit service so that patroni can take over
  include_recipe "postgresql::disable"
end

# This template is needed to make the gitlab-patronictl work
template "/opt/gitlab/etc/gitlab-patroni-rc" do
  owner 'root'
  group 'root'
end

# when the node is not boostrapped and is not master
# remove data_dir to bootstrap replica in next step
# if patroni_helper.cluster_initialized?
#   should_not_remove = patroni_helper.node_bootstrapped?  || patroni_helper.is_master?
#   execute "rm -rf #{node['gitlab']['postgresql']['data_dir']}" do
#     not_if { should_not_remove }
#   end
# end

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
  only_if { patroni_helper.node_status == 'running' }
  # only_if "/opt/gitlab/embedded/bin/sv status patroni && #{install_directory}/patronictl -c #{patroni_config_path} list | grep #{node.name} | grep running"
end
