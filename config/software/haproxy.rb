#
## Copyright:: Copyright (c) 2016 GitLab Inc
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name "haproxy"
default_version "1.6.6"


source url: "http://www.haproxy.org/download/1.6/src/haproxy-#{version}.tar.gz",
       sha256: "fdb03d63078cc3c688bb6d39fc75dcc158d65356e4c8e1c459033ebeddff55f5"

dependency "pcre"
dependency "openssl"

relative_path "haproxy-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  opts = [
    "PREFIX=#{install_dir}/embedded",
    "TARGET=generic",
    "USE_PCRE=1",
    "USE_OPENSSL=1",
    "USE_ZLIB=1"
  ].join(" ")

  make "#{opts} -j #{workers}", env: env
  make "install-bin #{opts} -j #{workers}", env: env
end
