#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

define :puma_config, listen_socket: nil, listen_tcp: nil, working_directory: nil, worker_timeout: 60, worker_memory_limit_min: nil, worker_memory_limit_max: nil, preload_app: false, worker_processes: 2, min_threads: 1, max_threads: 4, pid: nil, stderr_path: nil, stdout_path: nil, relative_url: nil, notifies: nil, owner: nil, group: nil, mode: nil do
  config_dir = File.dirname(params[:name])

  directory config_dir do
    recursive true
    action :create
  end

  template params[:name] do
    source "puma.rb.erb"
    mode "0644"
    owner params[:owner] if params[:owner]
    group params[:group] if params[:group]
    mode params[:mode]   if params[:mode]
    variables params
    notifies(*params[:notifies]) if params[:notifies]
  end
end
