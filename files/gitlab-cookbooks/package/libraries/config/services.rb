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

require_relative '../helpers/services_helper.rb'

module Services
  # Define the services included in every GitLab Edition
  class BaseServices < ::Services::Config
    # Define all gitlab cookbook services
    service 'logrotate',          groups: [DEFAULT_GROUP, SYSTEM_GROUP]
    service 'node_exporter',      groups: [DEFAULT_GROUP, SYSTEM_GROUP, 'prometheus']
    service 'gitlab_rails',       groups: [DEFAULT_GROUP, 'rails']
    service 'unicorn',            groups: [DEFAULT_GROUP, 'rails']
    service 'sidekiq',            groups: [DEFAULT_GROUP, 'rails', 'sidekiq']
    service 'gitlab_monitor',     groups: [DEFAULT_GROUP, 'rails', 'prometheus']
    service 'gitlab_workhorse',   groups: [DEFAULT_GROUP, 'rails']
    service 'redis',              groups: [DEFAULT_GROUP, 'redis']
    service 'redis_exporter',     groups: [DEFAULT_GROUP, 'redis', 'prometheus']
    service 'gitaly',             groups: [DEFAULT_GROUP]
    service 'postgresql',         groups: [DEFAULT_GROUP, 'postgres']
    service 'nginx',              groups: [DEFAULT_GROUP]
    service 'prometheus',         groups: [DEFAULT_GROUP, 'prometheus']
    service 'postgres_exporter',  groups: [DEFAULT_GROUP, 'prometheus', 'postgres']
    service 'mailroom'
    service 'gitlab_pages'
    service 'mattermost'
    service 'registry'
  end

  # Define the services included in the EE edition of GitLab
  class EEServices < ::Services::Config
    service 'sentinel',         groups: ['redis']
    service 'geo_logcursor',    groups: ['geo']
    service 'geo_postgresql',   groups: %w(geo postgres)
    service 'pgbouncer',        groups: ['postgres']
    service 'repmgrd',          groups: ['postgres']
    service 'consul',           groups: ['ha']
    service 'sidekiq_cluster',  groups: ['sidekiq']
  end
end
