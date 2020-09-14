#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

name 'libseccomp'

default_version '2.4.4'

license 'LGPL-2.1'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source url: "https://github.com/seccomp/libseccomp/releases/download/v#{version}/libseccomp-#{version}.tar.gz",
       sha256: '4e79738d1ef3c9b7ca9769f1f8b8d84fc17143c2c1c432e53b9c64787e0ff3eb'

relative_path "libseccomp-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_command = [
    './configure',
    "--prefix=#{install_dir}/embedded",
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
