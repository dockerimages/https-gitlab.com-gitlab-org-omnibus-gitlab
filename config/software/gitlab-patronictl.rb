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

require 'digest'

name 'gitlab-patronictl'

license 'Apache-2.0'
license_file File.expand_path('LICENSE', Omnibus::Config.project_root)

skip_transitive_dependency_licensing true

# This 'software' is self-contained in this file. Use the file contents
# to generate a version string.
default_version Digest::MD5.file(__FILE__).hexdigest

build do
  block do
    open("#{install_dir}/bin/gitlab-patronictl", 'w') do |file|
      file.print <<-EOH
#!/bin/sh

error_echo()
{
  echo "$1" 2>& 1
}

gitlab_psql_rc='/opt/gitlab/etc/gitlab-psql-rc'


if ! [ -f ${gitlab_psql_rc} ] || ! [ -r ${gitlab_psql_rc} ] ; then
  error_echo "$0 error: could not load ${gitlab_psql_rc}"
  error_echo "Either you are not allowed to read the file, or it does not exist yet."
  error_echo "You can generate it with:   sudo gitlab-ctl reconfigure"
  exit 1
fi

. "${gitlab_psql_rc}"

cd /tmp; exec /opt/gitlab/embedded/bin/chpst -U ${psql_user} /opt/gitlab/embedded/bin/patronictl -c /var/opt/gitlab/patroni/patroni.yml "$@"
      EOH
    end
  end

  command "chmod 755 #{install_dir}/bin/gitlab-patronictl"
end
