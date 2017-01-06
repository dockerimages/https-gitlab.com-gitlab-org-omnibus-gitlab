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
name 'libqb'
default_version '1.0.1'

license 'GPL-2.0'

version '1.0.1' do
  source sha256: '23047f8b0adae70d19be4f403704e792772ea8812e629e84a6f5910988518f2e'
end

source url: "https://github.com/ClusterLabs/libqb/releases/download/v#{version}/libqb-#{version}.tar.gz"

relative_path "libqb-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command './autogen.sh', env: env
  command "./configure --prefix=#{install_dir}/embedded", env: env
  make env: env
  make 'install', env: env
end
