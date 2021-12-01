#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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
pgb_helper = PgbouncerHelper.new(node)
pgbouncer_static_etc_dir = node['pgbouncer']['env_directory']

node.default['pgbouncer']['unix_socket_dir'] ||= node['pgbouncer']['data_directory']

include_recipe 'postgresql::user'

socket_dirs = Array.new(node['pgbouncer']['number_of_instances']) do |i|
  File.join(node['pgbouncer']['unix_socket_dir'], i.to_s)
end

log_dirs = Array.new(node['pgbouncer']['number_of_instances']) do |i|
  File.join(node['pgbouncer']['log_directory'], i.to_s)
end

[
  node['pgbouncer']['log_directory'],
  node['pgbouncer']['data_directory'],
  pgbouncer_static_etc_dir
].concat(socket_dirs, log_dirs).each do |dir|
  directory dir do
    owner account_helper.postgresql_user
    mode '0700'
    recursive true
  end
end

node['pgbouncer']['number_of_instances'].times do |i|
  template "#{node['pgbouncer']['data_directory']}/pgbouncer.#{i}.ini" do
    source "pgbouncer.ini.erb"
    variables lazy { node['pgbouncer'].to_hash.merge!(index: i, multiple: pgb_helper.multiple?) }
    owner account_helper.postgresql_user
    group account_helper.postgresql_group
    mode '0600'
    notifies :run, 'execute[reload pgbouncer]'
  end
end

env_dir pgbouncer_static_etc_dir do
  variables node['pgbouncer']['env']
  notifies :restart, "runit_service[pgbouncer]"
end

template "#{node['pgbouncer']['data_directory']}/pg_auth" do
  source "pg_auth.erb"
  variables(node['pgbouncer'])
  helper(:pgb_helper) { pgb_helper }
end

subservice_dir = "#{node['runit']['sv_dir']}/pgbouncer/instances"

directory subservice_dir do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

node['pgbouncer']['number_of_instances'].times do |i|
  runit_service "pgbouncer-#{i}" do
    managed_service false
    sv_dir subservice_dir
    service_dir subservice_dir
    run_template_name 'pgbouncer-instance'
    log_template_name 'pgbouncer'
    options(
      username: node['postgresql']['username'],
      groupname: node['postgresql']['group'],
      data_directory: node['pgbouncer']['data_directory'],
      log_directory: "#{node['pgbouncer']['log_directory']}/#{i}",
      env_dir: pgbouncer_static_etc_dir,
      index: i
    )
    action :create
  end
end

runit_service 'pgbouncer' do
  control(['t', 'h'])
  options(
    data_directory: node['pgbouncer']['data_directory'],
    log_directory: node['pgbouncer']['log_directory'],
    subservice_dir: subservice_dir,
    number_of_instances: node['pgbouncer']['number_of_instances']
  )
end

file 'databases.json' do
  path lazy { node['pgbouncer']['databases_json'] }
  user lazy { node['pgbouncer']['databases_ini_user'] }
  group account_helper.postgresql_group
  mode '0600'
  content node['pgbouncer']['databases'].to_json
  notifies :run, 'execute[generate databases.ini]', :immediately
end

execute 'generate databases.ini' do
  command lazy {
    <<~EOF
    /opt/gitlab/bin/gitlab-ctl pgb-notify \
     --databases-json #{node['pgbouncer']['databases_json']} \
     --databases-ini #{node['pgbouncer']['databases_ini']} \
     --hostuser #{node['pgbouncer']['databases_ini_user']} \
     --hostgroup #{account_helper.postgresql_group} \
     --pg-host #{node['pgbouncer']['listen_addr']} \
     --pg-port #{node['pgbouncer']['listen_port']} \
     --user #{node['postgresql']['pgbouncer_user']}
    EOF
  }
  action :nothing
  not_if do
    node['consul']['watchers'].include?('postgresql') &&
      File.exist?(node['pgbouncer']['databases_ini'])
  end
  retries 3
end

execute 'reload pgbouncer' do
  command '/opt/gitlab/bin/gitlab-ctl hup pgbouncer'
  action :nothing
  only_if { pgb_helper.running? }
end

execute 'start pgbouncer' do
  command '/opt//gitlab/bin/gitlab-ctl start pgbouncer'
  action :nothing
  not_if { pgb_helper.running? }
end
