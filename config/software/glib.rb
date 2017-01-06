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
name 'glib'
default_version '2.51.0'

license 'GPL-2.0'

dependency 'pcre'
dependency 'libxml2'
dependency 'libxslt'

version '2.51.0' do
  source sha256: 'f113b7330f4b4a43e3e401fe7849e751831060d574bd936a63e979887137a74a'
end

source url: "https://download.gnome.org/sources/glib/#{version[/\d+\.\d+/]}/glib-#{version}.tar.xz",
       unsafe: true

relative_path "glib-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command "./configure --prefix=#{install_dir}/embedded " \
    '--disable-libmount ' \
    ' --with-libiconv=gnu', env: env
  make env: env
  make 'install', env: env
end
