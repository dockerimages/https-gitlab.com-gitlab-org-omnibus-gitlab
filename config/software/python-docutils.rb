#
## Copyright:: Copyright (c) 2014 GitLab.com
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

name "python-docutils"

default_version "0.12"

license "Public Domain"
license_file "http://docutils.sourceforge.net/COPYING.txt"

dependency "python3"

source url: "http://vorboss.dl.sourceforge.net/project/docutils/docutils/#{version}/docutils-#{version}.tar.gz",
       sha256: "c7db717810ab6965f66c8cf0398a98c9d8df982da39b4cd7f162911eb89596fa"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  cwd = "#{Omnibus::Config.source_dir}/python-docutils/docutils-#{version}"

  command "#{install_dir}/embedded/bin/python3 setup.py install", env: env, cwd: cwd
end
