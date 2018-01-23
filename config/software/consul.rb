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

name 'consul'
default_version 'v1.0.2'

license 'MPL-2.0'
license_file 'LICENSE'

source git: 'https://github.com/hashicorp/consul.git'

relative_path 'src/github.com/hashicorp/consul'

build do
  env = {}
  env['GOPATH'] = "#{Omnibus::Config.source_dir}/consul"
  env['PATH'] = "#{ENV['PATH']}:#{env['GOPATH']}/bin"
  command 'make dev', env: env
  copy 'bin/consul', "#{install_dir}/embedded/bin/"
end
