#
## Copyright:: Copyright (c) 2021 GitLab Inc.
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

name 'spamcheck'
version = Gitlab::Version.new('spamcheck', 'jwanjohi-omnibus-arm-fix')

default_version version.print(false)

license 'MIT'

source git: version.remote

# dependency 'libtensorflow'
runtime_dependency "libgfortran"
runtime_dependency "libquadmath"
runtime_dependency "libz"
runtime_dependency "libhdf5"
runtime_dependency "libsz"
runtime_dependency "libaec"
runtime_dependency "libtensorflowlite_c"

relative_path 'src/gitlab-org/spamcheck'

arch = OhaiHelper.arm? ? 'arm' : 'amd64'

build do
  command "mkdir -p #{install_dir}/embedded/service"
  command "pip install --prefix=#{install_dir}/embedded -r tools/preprocess_helper/dist/requirements.txt"
  copy "tools/preprocess_helper/dist", "#{install_dir}/embedded/service/spamcheck"
  copy "app/inspector/#{arch}", "#{install_dir}/embedded/lib"

  env = {}
  env['GOPATH'] = "#{Omnibus::Config.source_dir}/spamcheck"
  env['PATH'] = "#{Gitlab::Util.get_env('PATH')}:#{env['GOPATH']}/bin"
  env['LIBRARY_PATH'] = "#{Gitlab::Util.get_env('LIBRARY_PATH')}:#{install_dir}/embedded/lib"
  env['LD_LIBRARY_PATH'] = "#{Gitlab::Util.get_env('LD_LIBRARY_PATH')}:#{install_dir}/embedded/lib"

  make 'build', env: env
  command "mkdir -p #{install_dir}/embedded/bin"
  move 'spamcheck', "#{install_dir}/embedded/bin/spamcheck"
end
