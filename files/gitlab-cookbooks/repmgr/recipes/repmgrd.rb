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
log_directory = node['repmgr']['log_directory']

runit_service 'repmgrd' do
  supervisor_owner account_helper.postgresql_user
  supervisor_group account_helper.postgresql_group
  options({
    username: node['gitlab']['postgresql']['username'],
    groupname: node['gitlab']['postgresql']['group'],
    dir: node['gitlab']['postgresql']['dir'],
    config_file: File.join(node['gitlab']['postgresql']['dir'], 'repmgr.conf'),
    log_directory: log_directory,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['repmgr'].to_hash)
end
