#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

name 'pg_plugins'
default_version 'f7960f1efa77f31e21a12172e60d2ff1efa824fd'

license 'PostgreSQL'
license_file 'LICENSE'

source git: 'https://github.com/michaelpq/pg_plugins.git'

dependency 'postgresql'

env = with_standard_compiler_flags(with_embedded_path)

relative_path "#{name}-#{version}"

build do
  make "-C jsonlog install", env: env
end
