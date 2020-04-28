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
    mode '0700'
  end
end

file patroni_config_path do
  content YAML.dump(node['patroni']['config'].to_hash)
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0600'
  notifies :reload, 'runit_service[patroni]', :delayed
end

default_auth_query = node.default['gitlab']['pgbouncer']['auth_query']
auth_query = node['gitlab']['pgbouncer']['auth_query']

template node['patroni']['config']['bootstrap']['post_bootstrap'] do
  source 'post-bootstrap.erb'
  owner account_helper.postgresql_user
  group account_helper.postgresql_group
  mode '0700'
  helper(:pg_helper) { pg_helper }
  variables(
    node['postgresql'].to_hash.merge(
      database_name: node['gitlab']['gitlab-rails']['db_database'],
      add_auth_function: default_auth_query.eql?(auth_query)
    )
  )
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

include_recipe "postgresql::disable"
