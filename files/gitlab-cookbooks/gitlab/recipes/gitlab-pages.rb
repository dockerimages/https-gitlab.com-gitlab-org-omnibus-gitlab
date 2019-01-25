#
# Copyright:: Copyright (c) 2016 GitLab B.V.
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

working_dir = node['gitlab']['gitlab-pages']['dir']
log_directory = node['gitlab']['gitlab-pages']['log_directory']
gitlab_pages_static_etc_dir = "/opt/gitlab/etc/gitlab-pages"
admin_secret_path = File.join(working_dir, "admin.secret")

[
  working_dir,
  log_directory,
  gitlab_pages_static_etc_dir
].each do |dir|
  directory dir do
    owner account_helper.gitlab_user
    mode '0700'
    recursive true
  end
end

ruby_block "authorize pages with gitlab" do
  block do
    GitlabPages.authorize_with_gitlab
  end

  not_if { node['gitlab']['gitlab-pages']['gitlab_id'] && node['gitlab']['gitlab-pages']['gitlab_secret'] }
  only_if { node['gitlab']['gitlab-pages']['access_control'] }
end

# Options may have changed in the previous step
ruby_block "re-populate GitLab Pages configuration options" do
  block do
    node.consume_attributes(Gitlab.hyphenate_config_keys)
  end
end

file File.join(working_dir, "VERSION") do
  content VersionHelper.version("/opt/gitlab/embedded/bin/gitlab-pages -version")
  notifies :restart, "service[gitlab-pages]"
end

template admin_secret_path do
  source "secret_token.erb"
  owner 'root'
  group account_helper.gitlab_group
  mode "0640"
  variables(secret_token: node['gitlab']['gitlab-pages']['admin_secret_token'])
  notifies :restart, "service[gitlab-pages]"
end

runit_service 'gitlab-pages' do
  options({
    dir: node['gitlab']['gitlab-pages']['dir'],
    external_http: node['gitlab']['gitlab-pages']['external_http'],
    external_https: node['gitlab']['gitlab-pages']['external_https'],
    listen_proxy: node['gitlab']['gitlab-pages']['listen_proxy'],
    cert: node['gitlab']['gitlab-pages']['cert'],
    cert_key: node['gitlab']['gitlab-pages']['cert_key'],
    metrics_address: node['gitlab']['gitlab-pages']['metrics_address'],
    username: node['gitlab']['user']['username'],
    inplace_chroot: node['gitlab']['gitlab-pages']['inplace_chroot'],
    domain: node['gitlab']['gitlab-pages']['domain'],
    pages_root: node['gitlab']['gitlab-pages']['pages_root'],
    status_uri: node['gitlab']['gitlab-pages']['status_uri'],
    max_connections: node['gitlab']['gitlab-pages']['max_connections'],
    log_format: node['gitlab']['gitlab-pages']['log_format'],
    log_verbose: node['gitlab']['gitlab-pages']['log_verbose'],
    redirect_http: node['gitlab']['gitlab-pages']['redirect_http'],
    use_http2: node['gitlab']['gitlab-pages']['use_http2'],
    artifacts_server: node['gitlab']['gitlab-pages']['artifacts_server'],
    artifacts_server_url: node['gitlab']['gitlab-pages']['artifacts_server_url'],
    artifacts_server_timeout: node['gitlab']['gitlab-pages']['artifacts_server_timeout'],
    access_control: node['gitlab']['gitlab-pages']['access_control'],
    gitlab_id: node['gitlab']['gitlab-pages']['gitlab_id'],
    gitlab_secret: node['gitlab']['gitlab-pages']['gitlab_secret'],
    auth_redirect_uri: node['gitlab']['gitlab-pages']['auth_redirect_uri'],
    auth_server: node['gitlab']['gitlab-pages']['auth_server'],
    auth_secret: node['gitlab']['gitlab-pages']['auth_secret'],
    admin_https_cert: node['gitlab']['gitlab-pages']['admin_https_cert'],
    admin_https_key: node['gitlab']['gitlab-pages']['admin_https_key'],
    admin_https_listener: node['gitlab']['gitlab-pages']['admin_https_listener'],
    admin_secret_path: File.join(node['gitlab']['gitlab-pages']['dir'], 'admin.secret'),
    admin_unix_listener: File.join(node['gitlab']['gitlab-pages']['dir'], 'admin.socket'),
    log_directory: log_directory
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['gitlab-pages'].to_hash)
end
