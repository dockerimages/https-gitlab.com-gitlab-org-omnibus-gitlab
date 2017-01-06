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
name 'pacemaker'
default_version '1.1.16'

license 'GPL-2.0'

dependency 'corosync'
dependency 'libuuid'
dependency 'libtool'
dependency 'glib'
dependency 'bzip2'

version '1.1.16' do
  source sha256: 'dffcae035975669a66ab545d45216a637496a251ee2114fa03d58acfcc969202'
end

source url: "https://github.com/ClusterLabs/pacemaker/archive/Pacemaker-#{version}.tar.gz"

relative_path "pacemaker-Pacemaker-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command './autogen.sh', env: env
  command "./configure --prefix=#{install_dir}/embedded " \
          '--with-corosync ' \
          "--with-initdir=#{install_dir}/embedded/etc/init.d", env: env
  make env: env
  make 'install', env: env
end
