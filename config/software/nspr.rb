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
name 'nspr'
default_version '4.13.1'
license 'GPL-2.0'

version '4.13.1' do
  source sha256: '5e4c1751339a76e7c772c0c04747488d7f8c98980b434dc846977e43117833ab'
end

source url: "https://ftp.mozilla.org/pub/nspr/releases/v#{version}/src/nspr-#{version}.tar.gz"

relative_path "nspr-#{version}/nspr"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command "./configure --prefix=#{install_dir}/embedded --enable-64bit"
  make 'all', env: env
  make 'install', env: env
end
