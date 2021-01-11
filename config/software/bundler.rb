#
# Copyright 2012-2016 Chef Software, Inc.
# Copyright 2017-2021 GitLab Inc.
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

name 'bundler'
# Pin the same version with one bundled to Ruby itself as far as possible
default_version '2.1.4'

license 'MIT'
license_file 'LICENSE.MD'

skip_transitive_dependency_licensing true

dependency 'rubygems'

build do
  patch source: "license/#{version}/add-license-file.patch"
  env = with_standard_compiler_flags(with_embedded_path)

  v_opts = "--version '#{version}'" unless version.nil?

  gem [
    'install bundler',
    v_opts,
    '--no-document --force'
  ].compact.join(' '), env: env
end
