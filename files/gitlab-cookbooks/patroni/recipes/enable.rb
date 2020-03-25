#
# Copyright:: Copyright (c) 2020 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

config_directory = node['patroni']['config_directory']
install_directory = node['patroni']['install_directory']
log_directory = node['patroni']['log_directory']
patroni_config_path = "#{config_directory}/patroni.yml"

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

replication_user = node['patroni']['users']['replication']['username']
replication_user_password = node['patroni']['users']['replication']['password']
replication_user_options = node['patroni']['users']['replication']['options']

postgresql_user superuser do
  password superuser_password.to_s unless superuser_password.nil?
  action :create
  options superuser_options
  not_if { pg_helper.is_slave? }
end

postgresql_user replication_user do
  password replication_user_password.to_s unless replication_user_password.nil?
  action :create
  options replication_user_options
  not_if { pg_helper.is_slave? }
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
  only_if { patroni_helper.node_status == 'running' }
end
