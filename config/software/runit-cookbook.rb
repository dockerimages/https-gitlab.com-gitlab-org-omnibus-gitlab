#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

name 'runit-cookbook'

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'gitlab-cookbooks'

source git: "https://gitlab.com/gitlab-org/build/omnibus-mirror/runit-cookbook.git"
default_version "4.3.0-gitlab"

build do
  command "mkdir -p #{install_dir}/embedded/cookbooks/runit"
  sync './libraries', "#{install_dir}/embedded/cookbooks/runit/libraries"
  copy './metadata.rb', "#{install_dir}/embedded/cookbooks/runit/metadata.rb"
  copy './README.md', "#{install_dir}/embedded/cookbooks/runit/README.md"
end
