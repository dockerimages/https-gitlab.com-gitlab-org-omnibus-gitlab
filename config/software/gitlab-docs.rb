#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

version = Gitlab::Version.new('gitlab-docs')

name 'gitlab-docs'
default_version version.print

license 'MIT'
license_file 'LICENSE'

dependency 'bundler'

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  bundle "install --jobs #{workers} --retry 5", env: env

  command 'yarn install --cache-folder .yarn-cache'

  # Create a symlink to gitlab-rails documentation
  command "ln -s #{install_dir}/embedded/service/gitlab-rails/doc #{Omnibus::Config.source_dir}/gitlab-docs/content/ee"

  # Compile documentation files
  bundle 'exec nanoc --env omnibus', env: env

  # Compress assets and delete originals
  command 'find public/ -type f \( -iname "*.html" -o -iname "*.js"  -o -iname "*.css"  -o -iname "*.svg" \) -exec gzip --keep --best --force --verbose {} \;'
  command 'find public/ -type f \( -iname "*.html" -o -iname "*.js"  -o -iname "*.css"  -o -iname "*.svg" \) -delete'

  # Move public folder with compiled docs to service
  command "mkdir -p #{install_dir}/embedded/service/gitlab-documentation"
  sync './public', "#{install_dir}/embedded/service/gitlab-documentation/"
end
