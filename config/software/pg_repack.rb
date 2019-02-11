#
# Copyright 2019 GitLab, Inc.
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

name "pg_repack"
default_version "1.4.4"

license "BSD"
license_file "COPYRIGHT"

dependency "postgresql"

source url: "https://github.com/reorg/pg_repack/archive/ver_#{version}.tar.gz",
       sha256: "b9f00d6e0b4d39460670610719d9e5510273b1396b18f2f2a5d35e080bcde255"

relative_path "pg_repack-ver_#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  make "-j #{workers} PG_CONFIG=#{install_dir}/embedded/bin/pg_config", env: env
  make "install", env: env
end
