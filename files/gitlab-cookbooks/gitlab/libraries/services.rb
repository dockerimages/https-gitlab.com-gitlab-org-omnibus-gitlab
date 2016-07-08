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

module Services
  class << self

    def list
      [
        "gitlab_rails",
        "redis",
        "postgresql",
        "unicorn",
        "sidekiq",
        "gitlab_workhorse",
        "mailroom",
        "nginx",
        "remote_syslog",
        "logrotate",
        "bootstrap",
        "mattermost",
        "gitlab_pages",
        "registry",
        "haproxy"
      ]
    end

    def isolated_run(*services)
      list.each do |sv|
        if services.include?(sv)
          Gitlab[sv]['enable'] = true
        else
          Gitlab[sv]['enable'] = false
        end
      end
    end
  end
end
