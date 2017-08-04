#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require_relative '../helpers/settings_helper.rb'

module Gitlab
  extend(Mixlib::Config)
  extend(SettingsHelper)

  ## Attributes that don't get passed to the node
  node nil
  gitlab_git_http_server Mash.new # legacy from GitLab 7.14, 8.0, 8.1
  git_data_dirs Mash.new

  ## Roles
  role('redis_sentinel').use { GitlabRails }
  role('redis_master')
  role('redis_slave')
  role('geo_primary')
  role('geo_secondary')

  ## Attributes directly on the node
  attribute('registry').use { Registry }
  attribute('repmgr')

  ## Attributes under node['gitlab']
  attribute_block 'gitlab' do
    # EE attributes
    ee_attribute('sidekiq_cluster').use { SidekiqCluster }
    ee_attribute('geo_postgresql').use  { GitlabGeo }
    ee_attribute('geo_secondary')
    ee_attribute('geo_logcursor')

    # Base GitLab attributes
    attribute('gitlab_shell', sequence: 10).use { GitlabShell } # Parse shell before rails for data dir settings
    attribute('gitlab_rails', sequence: 15).use { GitlabRails } # Parse rails first as others may depend on it
    attribute('nginx',        sequence: 40).use { Nginx } # Parse nginx last so all external_url are parsed before it
    attribute('gitlab_workhorse').use           { GitlabWorkhorse }
    attribute('logging').use                    { Logging }
    attribute('redis').use                      { Redis }
    attribute('postgresql').use                 { Postgresql }
    attribute('unicorn').use                    { Unicorn }
    attribute('mailroom').use                   { IncomingEmail }
    attribute('mattermost').use                 { GitlabMattermost }
    attribute('gitlab_pages').use               { GitlabPages }
    attribute('prometheus').use                 { Prometheus }
    attribute('external_url',             default: nil)
    attribute('mattermost_external_url',  default: nil)
    attribute('pages_external_url',       default: nil)
    attribute('runtime_dir',              default: nil)
    attribute('bootstrap')
    attribute('omnibus_gitconfig')
    attribute('manage_accounts')
    attribute('manage_storage_directories')
    attribute('user')
    attribute('gitlab_ci')
    attribute('sidekiq')
    attribute('mattermost_nginx')
    attribute('pages_nginx')
    attribute('registry_nginx')
    attribute('remote_syslog')
    attribute('logrotate')
    attribute('high_availability')
    attribute('web_server')
    attribute('gitaly')
    attribute('node_exporter')
    attribute('redis_exporter')
    attribute('postgres_exporter')
    attribute('gitlab_monitor')
    attribute('prometheus_monitoring')
    attribute('pgbouncer')
    attribute('sentinel')
  end
end
