#
## Copyright:: Copyright (c) 2018 GitLab.com
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

name 'pgbouncer-exporter'

default_version '0.2.1'

license 'MIT'
license_file 'https://github.com/spreaker/prometheus-pgbouncer-exporter/blob/master/LICENSE.txt'

dependency 'python3'

build do
  env = with_standard_compiler_flags(with_embedded_path)
  # psycopyg2 needs pg_config in the PATH
  env['PATH'] = "#{install_dir}/embedded/bin" + File::PATH_SEPARATOR + ENV['PATH']

  command "#{install_dir}/embedded/bin/pip3 install --upgrade setuptools"
  # This is needed until https://github.com/spreaker/prometheus-pgbouncer-exporter/pull/4 is merged
  command "#{install_dir}/embedded/bin/pip3 install PyYAML==3.12"
  # The Wheels version of psycopyg2 bundles pre-compiled libraries. This works around the problem
  # by forcing a source install: http://initd.org/psycopg/docs/install.html#disabling-wheel-packages-for-psycopg-2-7
  command "#{install_dir}/embedded/bin/pip3 install --no-binary :all: prometheus-pgbouncer-exporter==#{version}", env: env
end
