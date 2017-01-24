# Copyright 2017 GitLab, Inc.
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

name 'pgpool-ii'
default_version '3.6.1'

license 'pgpool-II'
license_file 'COPYING'

dependency 'postgresql_new'

source url: 'http://www.pgpool.net/mediawiki/images/pgpool-II-3.6.1.tar.gz',
       sha256: '244f99a70198b5861a63b2fe3e44ac39d2819f6aa6497f62958c6afa2750d94c'

relative_path "pgpool-II-#{default_version}"

build do
  pg_config = "#{install_dir}/embedded/postgresql/9.6.1/bin/pg_config"

  env = with_standard_compiler_flags(with_embedded_path)
        .merge('PG_CONFIG' => pg_config)

  command "./configure --prefix=#{install_dir}/embedded" \
          " --with-pgsql-includedir=`#{pg_config} --includedir`" \
          " --with-pgsql-libdir=`#{pg_config} --libdir`",
          env: env

  make "-j #{workers}", env: env
  make 'install', env: env

  # Compile pgpool_recovery
  recovery_dir = "#{project_dir}/src/sql/pgpool-recovery"

  make "-j #{workers}", env: env, cwd: recovery_dir
  make 'install', env: env, cwd: recovery_dir
end
