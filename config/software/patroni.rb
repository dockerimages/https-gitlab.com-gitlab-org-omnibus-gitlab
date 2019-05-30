#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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
name 'patroni'
default_version '1.5.5'

license 'MIT'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

whitelist_file /psycopg2\/.libs\/.+/
# whitelist_file /psycopg2/

dependency 'python3'
dependency 'postgresql'

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['PATH'] = "#{install_dir}/embedded/postgresql/9.6/bin" + File::PATH_SEPARATOR + Gitlab::Util.get_env('PATH')
  command "#{install_dir}/embedded/bin/pip3 install --upgrade setuptools", env: env
  command "#{install_dir}/embedded/bin/pip3 install psycopg2-binary", env: env
  command "#{install_dir}/embedded/bin/pip3 install psycopg2", env: env
  # command "#{install_dir}/embedded/bin/pip3 install patroni[consul]==#{version}", env: env
end
