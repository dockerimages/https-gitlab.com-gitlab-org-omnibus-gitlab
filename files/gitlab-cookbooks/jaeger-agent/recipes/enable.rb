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
account_helper = AccountHelper.new(node)

working_dir = node['jaeger_agent']['dir']
log_directory = node['jaeger_agent']['log_directory']

jaeger_user = account_helper.jaeger_user
jaeger_group = account_helper.jaeger_group

account 'user and group for jaeger' do
  username jaeger_user
  uid node['jaeger']['uid']
  ugid jaeger_group
  groupname jaeger_group
  gid node['jaeger']['gid']
  shell node['jaeger']['shell']
  home node['jaeger']['home']
  manage node['gitlab']['manage-accounts']['enable']
end

directory working_dir do
  owner jaeger_user
  group jaeger_group
  mode '0700'
  recursive true
end

directory log_directory do
  owner jaeger_user
  group jaeger_group
  mode '0700'
  recursive true
end

runit_service 'jaeger-agent' do
  options({
    username: jaeger_user,
    group: jaeger_group,
    dir: working_dir,
    log_directory: log_directory,
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['jaeger_agent'].to_hash)
end

if node['gitlab']['bootstrap']['enable']
  execute "/opt/gitlab/bin/gitlab-ctl start jaeger-agent" do
    retries 20
  end
end

file File.join(working_dir, "VERSION") do
  content VersionHelper.version("/opt/gitlab/embedded/bin/jaeger-agent --version")
  notifies :hup, "runit_service[jaeger-agent]"
end
