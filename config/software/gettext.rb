# Copyright:: Copyright (c) 2019 GitLab Inc.
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

name 'gettext'

default_version '0.19.8.1'

version '0.19.8.1' do
  source md5: '97e034cf8ce5ba73a28ff6c3c0638092'
end

# using a git checkout would invoke the need to also clone gnulib, which is
# messy
source url: "https://ftp.gnu.org/pub/gnu/gettext/gettext-#{version}.tar.gz"

dependency 'libiconv'
dependency 'ncurses'
dependency 'libxml2'
dependency 'bzip2'
dependency 'liblzma'
dependency 'ncurses'

license 'GPL v3'
license_file 'COPYING'

skip_transitive_dependency_licensing true

build do
    env = with_standard_compiler_flags(with_embedded_path)

    patch source: 'CVE-2018-18751.patch'

    command ['./autogen.sh',
             "--with-libiconv-prefix=#{install_dir}/embedded",
             "--with-ncurses-prefix=#{install_dir}/embedded",
             "--with-libxml2-prefix==#{install_dir}/embedded",
             "--prefix=#{install_dir}/embedded"].join(' '), env: env 
    make env: env
    make "install", env: env
end
