#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

user = account_helper.haproxy_user
group = account_helper.haproxy_group
haproxy_uid = node['gitlab']['haproxy']['uid']
haproxy_gid = node['gitlab']['haproxy']['gid']

install_dir = node['package']['install-dir']
ssl_certs_dir =  File.join(install_dir, "embedded/ssl/certs")
working_dir = node['gitlab']['haproxy']['dir']
log_directory = node['gitlab']['haproxy']['log_directory']

account "Haproxy registry user and group" do
  username user
  uid haproxy_uid
  ugid group
  groupname group
  gid haproxy_gid
  shell '/bin/sh'
  home working_dir
  manage node['gitlab']['manage-accounts']['enable']
end

[
  working_dir,
  log_directory,
].each do |dir|
  directory dir do
    owner user
    group group
    mode '0700'
    recursive true
  end
end

template File.join(working_dir, 'haproxy.cfg') do
  source 'haproxy.cfg.erb'
  owner user
  group group
  variables(
    user: node['gitlab']['haproxy']['username'],
    group: node['gitlab']['haproxy']['group'],
    working_dir: working_dir,
    ca_base: File.join(ssl_certs_dir, 'certs'),
    crt_base: File.join(ssl_certs_dir, 'private'),
    global: node['gitlab']['haproxy']['global'],
    defaults: node['gitlab']['haproxy']['defaults'],
    listen: node['gitlab']['haproxy']['listen']
  )
  mode "0644"
  helpers SyntaxCheckHelper
  notifies :restart, "service[haproxy]"
end

runit_service 'haproxy' do
  down node['gitlab']['haproxy']['ha']
  options({
    :log_directory => log_directory
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['haproxy'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start haproxy" do
    retries 20
  end
end

file File.join(working_dir, "VERSION") do
  content VersionHelper.version("/opt/gitlab/embedded/sbin/haproxy -v")
  notifies :restart, "service[haproxy]"
end
