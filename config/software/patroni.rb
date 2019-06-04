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

dependency 'python3'
dependency 'postgresql_new'

PGVERSION = 10
LIB_PATH = %W(#{install_dir}/embedded/lib #{install_dir}/embedded/lib64 #{install_dir}/lib #{install_dir}/lib64 #{install_dir}/libexec #{install_dir}/embedded/postgresql/#{PGVERSION}/lib).freeze

env = {
  'CFLAGS' => "-I#{install_dir}/embedded/include -O3 -g -pipe",
  'CPPFLAGS' => "-I#{install_dir}/embedded/include -O3 -g -pipe",
  'LDFLAGS' => "-Wl,-rpath,#{LIB_PATH.join(',-rpath,')} -L#{LIB_PATH.join(' -L')} -I#{install_dir}/embedded/include",
  'PATH' => "#{install_dir}/bin:#{install_dir}/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
}

build do
  # command "#{install_dir}/embedded/bin/pip3 install --upgrade setuptools", env: env
  command "#{install_dir}/embedded/bin/pip3 install patroni[consul]==#{version}", env: env
end
