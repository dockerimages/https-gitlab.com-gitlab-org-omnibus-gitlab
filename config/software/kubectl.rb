#
## Copyright:: Copyright (c) 2016 GitLab Inc.
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

name "kubectl"
default_version "1.3.0"

license "Apache-2.0"
license_file "https://github.com/kubernetes/kubernetes/blob/v#{version}/LICENSE"

source url: "http://storage.googleapis.com/kubernetes-release/release/v#{version}/bin/linux/amd64/kubectl",
       sha256: "f40b2d0ff33984e663a0dea4916f1cb9041abecc09b11f9372cdb8049ded95dc"

build do
  copy "kubectl", "#{install_dir}/embedded/bin"
  command "chmod +x #{install_dir}/embedded/bin/kubectl"
end
