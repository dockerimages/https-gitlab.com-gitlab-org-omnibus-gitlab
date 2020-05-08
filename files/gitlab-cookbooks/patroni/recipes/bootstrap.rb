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

account_helper = AccountHelper.new(node)
pg_helper = PgHelper.new(node)

postgresql_username = account_helper.postgresql_user
postgresql_group = account_helper.postgresql_group

ssl_cert_file = File.absolute_path(node['postgresql']['ssl_cert_file'], node['postgresql']['data_dir'])
ssl_key_file = File.absolute_path(node['postgresql']['ssl_key_file'], node['postgresql']['data_dir'])

file ssl_cert_file do
  content node['postgresql']['internal_certificate']
  owner postgresql_username
  group postgresql_group
  mode 0400
  sensitive true
  only_if { node['postgresql']['ssl'] == 'on' }
end

file ssl_key_file do
  content node['postgresql']['internal_key']
  owner postgresql_username
  group postgresql_group
  mode 0400
  sensitive true
  only_if { node['postgresql']['ssl'] == 'on' }
end

execute "/opt/gitlab/embedded/bin/initdb -D #{node['postgresql']['data_dir']} -E UTF8" do
  user postgresql_username
  not_if { pg_helper.bootstrapped? }
end

postgresql_config 'gitlab' do
  pg_helper pg_helper
end
