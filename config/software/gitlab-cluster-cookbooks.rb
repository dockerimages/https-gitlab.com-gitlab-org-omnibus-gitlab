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

name 'gitlab-cluster-cookbooks'

license 'Apache-2.0'
license_file File.expand_path('LICENSE', Omnibus::Config.project_root)

source path: File.expand_path('files/gitlab-cookbooks', Omnibus::Config.project_root)

build do
  cookbook_name = 'gitlab-cluster'

  command "mkdir -p #{install_dir}/embedded/cookbooks"

  %w(consul package runit gitlab-cluster gitlab).each do |cookbook|
    sync "./#{cookbook}", "#{install_dir}/embedded/cookbooks/#{cookbook}"
  end

  copy './solo.rb', "#{install_dir}/embedded/cookbooks/solo.rb"

  erb dest: "#{install_dir}/embedded/cookbooks/dna.json",
      source: 'dna.json.erb',
      mode: 0644,
      vars: { master_cookbook: cookbook_name }
end
