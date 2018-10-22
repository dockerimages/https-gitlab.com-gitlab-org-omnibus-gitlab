#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

define :puma_service, rails_app: nil, user: nil do
  rails_app = params[:rails_app]
  rails_home = node['gitlab'][rails_app]['dir']
  svc = params[:name]
  user = params[:user]

  omnibus_helper = OmnibusHelper.new(node)

  metrics_dir = File.join(node['gitlab']['runtime-dir'].to_s, 'gitlab/puma') unless node['gitlab']['runtime-dir'].nil?

  puma_etc_dir = File.join(rails_home, "etc")
  puma_working_dir = File.join(rails_home, "working")

  puma_listen_socket = node['gitlab'][svc]['socket']
  puma_pidfile = node['gitlab'][svc]['pidfile']
  puma_log_dir = node['gitlab'][svc]['log_directory']
  puma_socket_dir = File.dirname(puma_listen_socket)

  [
    puma_log_dir,
    File.dirname(puma_pidfile)
  ].each do |dir_name|
    directory dir_name do
      owner user
      mode '0700'
      recursive true
    end
  end

  directory puma_socket_dir do
    owner user
    group AccountHelper.new(node).web_server_group
    mode '0750'
    recursive true
  end

  puma_listen_tcp = [node['gitlab'][svc]['listen'], node['gitlab'][svc]['port']].join(':')

  puma_rb = File.join(puma_etc_dir, "puma.rb")
  puma_config puma_rb do
    listen_socket puma_listen_socket
    listen_tcp puma_listen_tcp
    worker_timeout node['gitlab'][svc]['worker_timeout']
    worker_memory_limit_min node['gitlab'][svc]['worker_memory_limit_min']
    worker_memory_limit_max node['gitlab'][svc]['worker_memory_limit_max']
    working_directory puma_working_dir
    worker_processes node['gitlab'][svc]['worker_processes']
    preload_app true
    stderr_path File.join(puma_log_dir, "puma_stderr.log")
    stdout_path File.join(puma_log_dir, "puma_stdout.log")
    relative_url node['gitlab'][svc]['relative_url']
    pid puma_pidfile
    install_dir node['package']['install-dir']
    owner "root"
    group "root"
    mode "0644"
    notifies :restart, "service[#{svc}]" if omnibus_helper.should_notify?(svc)
  end

  runit_service svc do
    down node['gitlab'][svc]['ha']
    restart_command 2 # Restart Puma using SIGUSR2
    template_name 'puma'
    control ['t']
    options({
      service: svc,
      user: user,
      rails_app: rails_app,
      puma_rb: puma_rb,
      log_directory: puma_log_dir,
      metrics_dir: metrics_dir,
      clean_metrics_dir: false
    }.merge(params))
    log_options node['gitlab']['logging'].to_hash.merge(node['gitlab'][svc].to_hash)
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start #{svc}" do
      retries 20
    end
  end
end
