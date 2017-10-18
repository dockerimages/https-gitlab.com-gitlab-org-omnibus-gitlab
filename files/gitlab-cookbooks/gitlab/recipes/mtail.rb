#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
account_helper = AccountHelper.new(node)
gitlab_user = account_helper.gitlab_user
mtail_log_dir = node['gitlab']['mtail']['log_directory']
mtail_progs_dir = File.join(node['gitlab']['mtail']['home'], 'progs')

directory mtail_log_dir do
  owner gitlab_user
  mode '0700'
  recursive true
end

directory mtail_progs_dir do
  owner gitlab_user
  mode '0755'
  recursive true
end

[
  'sidekiq.mtail',
  'unicorn.mtail'
].each do [file]
  template File.join(mtail_progs_dir, file) do
    source File.join('mtail', file)
    owner gitlab_user
    mode '0644'
  end
end

logs = [
  File.join(node['gitlab']['unicorn']['log_directory'], 'unicorn_stderr.log'),
  File.join(node['gitlab']['sidekiq']['log_directory'], 'current')
]

runtime_flags = PrometheusHelper.new(node).flags('mtail')
runit_service 'mtail' do
  options({
    log_directory: mtail_log_dir,
    logs: logs.join(','),
    flags: runtime_flags
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['registry'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute '/opt/gitlab/bin/gitlab-ctl start mtail' do
    retries 20
  end
end
