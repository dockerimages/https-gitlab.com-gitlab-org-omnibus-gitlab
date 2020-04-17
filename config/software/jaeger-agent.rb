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

name 'jaeger-agent'
version = Gitlab::Version.new('jaeger', 'v1.17.1')
default_version version.print

license 'Apache-2.0'
license_file 'LICENSE'

source git: version.remote

skip_transitive_dependency_licensing true

relative_path 'src/github.com/jaegertracing/jaeger'

build do
  env = {}
  env['GOPATH'] = "#{Omnibus::Config.source_dir}/jaeger"
  env['PATH'] = "#{Gitlab::Util.get_env('PATH')}:#{env['GOPATH']}/bin"

  command 'git submodule update --init --recursive', env: env
  command 'make install-tools', env: env
  command 'make build-ui', env: env
  command 'make build-binaries-linux', env: env
  mkdir "#{install_dir}/embedded/bin"
  copy 'cmd/agent/agent-linux', "#{install_dir}/embedded/bin/jaeger-agent"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/jaeger-agent.csv"
end
