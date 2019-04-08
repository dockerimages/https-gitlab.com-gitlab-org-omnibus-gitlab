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

name 'libgpg-error'
default_version 'libgpg-error-1.36'

license 'LGPL-2.1'
license_file 'COPYING.LIB'

skip_transitive_dependency_licensing true

source git: "git://git.gnupg.org/libgpg-error.git"

relative_path "libgpg-error-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command './autogen.sh', env: env
  command './configure ' \
    "--prefix=#{install_dir}/embedded --disable-doc", env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude 'embedded/bin/gpg-error-config'
