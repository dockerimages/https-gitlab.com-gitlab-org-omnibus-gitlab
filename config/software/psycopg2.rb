#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

name 'psycopg2'
default_version '2_8_4'

license 'LGPL'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: "https://github.com/psycopg/psycopg2.git"

dependency 'python3'
dependency 'postgresql'

pg_major_version = '11'
pg_libpq = 'libpq.so.5'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  patch source: "#{version}/eliminate-pg-config.patch"

  command "#{install_dir}/embedded/bin/python3 setup.py build_ext --install-dir=#{install_dir} --pg-version=#{pg_major_version}", env: env
  command "#{install_dir}/embedded/bin/python3 setup.py install", env: env

  link "#{install_dir}/embedded/postgresql/#{pg_major_version}/lib/#{pg_libpq}", "#{install_dir}/embedded/lib/#{pg_libpq}"
end
