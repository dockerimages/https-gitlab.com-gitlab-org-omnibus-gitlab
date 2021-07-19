#
## Copyright:: Copyright (c) 2021 GitLab Inc.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name 'spamcheck'
version = Gitlab::Version.new('spamcheck', 'main')

default_version version.print(false)

license 'MIT'

source git: version.remote

relative_path 'src/gitlab-org/spamcheck'

build do
  env = {}
  env['GOPATH'] = "#{Omnibus::Config.source_dir}/spamcheck"
  env['PATH'] = "#{Gitlab::Util.get_env('PATH')}:#{env['GOPATH']}/bin"

  make 'build', env: env
  move 'spamcheck', "#{install_dir}/embedded/bin/spamcheck"

  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=csv --save=license.csv"
  copy "license.csv", "#{install_dir}/licenses/spamcheck.csv"
end
