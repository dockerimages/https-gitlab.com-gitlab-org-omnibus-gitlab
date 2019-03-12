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
require 'chef_helper'

describe 'gitlab-ee::pgpass' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      {
        geo_secondary: {
          db_database: 'gitlabdb',
          db_username: 'myusername',
          db_password: 'mypassword',
          db_port: '1234',
          db_host: 'myhost'
        }
      }
    )
  end

  it 'should create the pgpass file for gitlab-geo-psql user' do
    expect(chef_run).to include_recipe('gitlab-ee::pgpass')
    expect(chef_run).to create_postgresql_pgpass('gitlab-psql').with(
      database: 'gitlabdb',
      database_username: 'myusername',
      database_password: 'mypassword',
      database_port: '1234',
      database_host: 'myhost'
    )
  end
end

describe 'gitlab-ee::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  it 'includes the pgpass recipe' do
    expect(chef_run).to include_recipe('gitlab-ee::pgpass')
  end
end
