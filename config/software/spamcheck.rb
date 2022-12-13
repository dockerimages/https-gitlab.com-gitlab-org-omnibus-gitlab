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
version = Gitlab::Version.new('spamcheck', '1.2.3')

default_version version.print

license 'MIT'
license_file 'LICENSE'

dependency 'python3'

source git: version.remote

relative_path 'src/gitlab-org/spamcheck'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command "#{install_dir}/embedded/bin/pip3 install tflite-runtime==2.10.0", env: env
  command "#{install_dir}/embedded/bin/pip3 install grpcio==1.44.0", env: env
  command "#{install_dir}/embedded/bin/pip3 install grpcio_reflection==1.44.0", env: env
  command "#{install_dir}/embedded/bin/pip3 install grpcio_tools==1.44.0", env: env
  command "#{install_dir}/embedded/bin/pip3 install python-json-logger==2.0.2", env: env
  command "#{install_dir}/embedded/bin/pip3 install ulid-py==1.1.0", env: env
  command "#{install_dir}/embedded/bin/pip3 install vyper-config==1.1.1", env: env
  command "#{install_dir}/embedded/bin/python3 -m grpc_tools.protoc --proto_path=${PWD} --python_out=${PWD} --grpc_python_out=${PWD} ${PWD}/api/v1/*.proto", env: env
  command "mkdir -p #{install_dir}/embedded/service/spamcheck", env: env

  sync './api', "#{install_dir}/embedded/service/spamcheck/api"
  sync './app', "#{install_dir}/embedded/service/spamcheck/app"
  sync './server', "#{install_dir}/embedded/service/spamcheck/server"

  copy './main.py', "#{install_dir}/embedded/service/spamcheck/"
  copy './VERSION', "#{install_dir}/embedded/service/spamcheck/"
end
