#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'protobuf-gem'
version = Gitlab::Version.new('protobuf-gem', '3.2.0')
default_version version.print

source git: version.remote

license 'BSD-3-Clause'
license_file 'LICENSE'

dependency 'curl'
dependency 'unzip'
dependency 'ruby'
dependency 'bundler'

build do
  env = with_standard_compiler_flags(with_embedded_path)
  source_dir = "#{Omnibus::Config.source_dir}/protobuf-gem"

  # Build the google-protobuf gem to ensure it works on the included gcc
  command "curl -LO https://github.com/google/protobuf/releases/download/#{version.print}/protoc-#{version.print(false)}-linux-x86_64.zip", env: env
  command "unzip protoc-#{version.print(false)}-linux-x86_64.zip", env: env
  command 'chmod -R 755 bin', env: env
  link "#{source_dir}/bin/protoc", "#{source_dir}/src"
  bundle "install --jobs #{workers} --path=gems --retry 5", cwd: "#{source_dir}/ruby", env: env
  bundle 'exec rake build clobber_package gem', cwd: "#{source_dir}/ruby", env: env
  gem "install #{source_dir}/ruby/pkg/google-protobuf-#{version.print(false)}.gem --local", env: env
end
