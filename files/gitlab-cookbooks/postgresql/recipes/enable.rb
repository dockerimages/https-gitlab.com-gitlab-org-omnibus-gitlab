#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
# License:: Apache License, Version 2.0
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
account_helper = AccountHelper.new(node)

include_recipe 'postgresql::directory_locations'

postgresql_log_dir = node['gitlab']['postgresql']['log_directory']
postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group
postgresql_data_dir_symlink = File.join(node['gitlab']['postgresql']['dir'], "data")

pg_helper = PgHelper.new(node)
patroni_helper = PatroniHelper.new(node)

include_recipe 'postgresql::user'

directory node['gitlab']['postgresql']['dir'] do
  owner postgresql_username
  mode "0755"
  recursive true
end

[
  node['gitlab']['postgresql']['data_dir'],
  postgresql_log_dir
].each do |dir|
  directory dir do
    owner postgresql_username
    mode "0700"
    recursive true
  end
end

link postgresql_data_dir_symlink do
  to node['gitlab']['postgresql']['data_dir']
  not_if { node['gitlab']['postgresql']['data_dir'] == postgresql_data_dir_symlink }
end

file File.join(node['gitlab']['postgresql']['home'], ".profile") do
  owner postgresql_username
  mode "0600"
  content <<-EOH
PATH=#{node['gitlab']['postgresql']['user_path']}
EOH
end

sysctl "kernel.shmmax" do
  value node['gitlab']['postgresql']['shmmax']
end

sysctl "kernel.shmall" do
  value node['gitlab']['postgresql']['shmall']
end

sem = [
  node['gitlab']['postgresql']['semmsl'],
  node['gitlab']['postgresql']['semmns'],
  node['gitlab']['postgresql']['semopm'],
  node['gitlab']['postgresql']['semmni'],
].join(" ")
sysctl "kernel.sem" do
  value sem
end

# This template is needed to make the gitlab-psql script and PgHelper work
template "/opt/gitlab/etc/gitlab-psql-rc" do
  owner 'root'
  group 'root'
end

if patroni_helper.master_on_initialization
  execute "/opt/gitlab/embedded/bin/initdb -D #{node['gitlab']['postgresql']['data_dir']} -E UTF8" do
    user postgresql_username
    not_if { pg_helper.bootstrapped? }
  end
end

# config files are updated if the node is master on initialization
# or if the patroni node has been bootstrapped
if patroni_helper.master_on_initialization || patroni_helper.node_bootstrapped?
  include_recipe 'postgresql::configs'
end

runit_log = node['gitlab']['postgresql']['logging_collector'] == 'off'
runit_service "postgresql" do
  down node['gitlab']['postgresql']['ha']
  supervisor_owner postgresql_username
  supervisor_group postgresql_group
  restart_on_update false
  control(['t'])
  log runit_log
  options({
    log_directory: postgresql_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['postgresql'].to_hash)
  not_if { patroni_helper.is_running? }
end

# This recipe must be ran BEFORE any calls to the binaries are made
# and AFTER the service has been defined
# to ensure the correct running version of PostgreSQL
# Only exception to this rule is "initdb" call few lines up because this should
# run only on new installation at which point we expect to have correct binaries.
include_recipe 'postgresql::bin'

execute "/opt/gitlab/bin/gitlab-ctl start postgresql" do
  retries 20
  only_if { node['gitlab']['bootstrap']['enable'] && patroni_helper.master_on_initialization }
end

###
# Create the database, migrate it, and create the users we need, and grant them
# privileges.
###

pg_port = node['gitlab']['postgresql']['port']
database_name = node['gitlab']['gitlab-rails']['db_database']
gitlab_sql_user = node['gitlab']['postgresql']['sql_user']
gitlab_sql_user_password = node['gitlab']['postgresql']['sql_user_password']
sql_replication_user = node['gitlab']['postgresql']['sql_replication_user']
sql_replication_password = node['gitlab']['postgresql']['sql_replication_password']

if node['gitlab']['gitlab-rails']['enable']
  postgresql_user gitlab_sql_user do
    password "md5#{gitlab_sql_user_password}" unless gitlab_sql_user_password.nil?
    action :create
    not_if { pg_helper.is_slave? }
  end

  execute "create #{database_name} database" do
    command "/opt/gitlab/embedded/bin/createdb --port #{pg_port} -h #{node['gitlab']['postgresql']['unix_socket_directory']} -O #{gitlab_sql_user} #{database_name}"
    user postgresql_username
    retries 30
    not_if { !pg_helper.is_running? || pg_helper.database_exists?(database_name) || pg_helper.is_slave? }
  end

  postgresql_user sql_replication_user do
    password "md5#{sql_replication_password}" unless sql_replication_password.nil?
    options %w(replication)
    action :create
    not_if { pg_helper.is_slave? }
  end
end

postgresql_extension 'pg_trgm' do
  database database_name
  action :enable
end

ruby_block 'warn pending postgresql restart' do
  block do
    message = <<~MESSAGE
      The version of the running postgresql service is different than what is installed.
      Please restart postgresql to start the new version.
      If patroni is enabled restart with
        sudo gitlab-ctl restart patroni
      otherwise restart with
        sudo gitlab-ctl restart postgresql
    MESSAGE
    LoggingHelper.warning(message)
  end
  only_if { pg_helper.is_running? && pg_helper.running_version != pg_helper.version }
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
