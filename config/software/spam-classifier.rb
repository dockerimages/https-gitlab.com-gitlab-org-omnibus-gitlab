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

name 'spam-classifier'

default_version '2.0.1'
source url: "https://glsec-spamcheck-ml-artifacts.storage.googleapis.com/spam-classifier/#{version}/gl-spam-classifier-#{version}.tar.gz",
       sha256: '1c0fc6e621d095baf149c89dfe2e9ec04de95c2cb072d442d4476b23b0d3310c'

license 'proprietary'
license_file 'LICENSE.md'

build do
  mkdir "#{install_dir}/embedded/service/spamcheck/spam-classifier"
  sync './', "#{install_dir}/embedded/service/spam-classifier/"
end
