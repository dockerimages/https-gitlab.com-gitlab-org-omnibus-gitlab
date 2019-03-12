#
# Copyright:: Copyright (c) 2019 GitLab Inc.
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
postgresql_psql_user = account_helper.postgresql_user
postgresql_username = node['gitlab']['geo-secondary']['db_username']
postgresql_password = node['gitlab']['geo-secondary']['db_password']
postgresql_host = node['gitlab']['geo-secondary']['db_host']
postgresql_port = node['gitlab']['geo-secondary']['db_port']
postgresql_database = node['gitlab']['geo-secondary']['db_database']

postgresql_pgpass postgresql_psql_user do
  database_username postgresql_username
  database_password postgresql_password
  database_host postgresql_host
  database_port postgresql_port
  database postgresql_database
end
