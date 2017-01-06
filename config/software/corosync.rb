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
name 'corosync'
default_version '2.4.2'

license 'GPL-2.0'

version '2.4.2' do
  source sha256: 'f26e3011309fe4bcce94b1dc20ea8c462f19483a73f3ca62f13b925d011a4ba9'
end

dependency 'nss'
dependency 'libqb'

source url: "http://build.clusterlabs.org/corosync/releases/corosync-#{version}.tar.gz"
relative_path "corosync-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command "./configure --prefix=#{install_dir}/embedded", env: env
  make env: env
  make 'install', env: env
end
