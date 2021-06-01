#
# Copyright:: Copyright (c) 2021 GitLab Inc.
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

require 'json'

add_command 'fetch-initial-root-password', 'Fetch the initial root password automatically generated or manually set via gitlab.rb', 2 do |cmd_name|
  unless File.exist?('/etc/gitlab/gitlab-secrets.json')
    log "/etc/gitlab/gitlab-secrets.json file not found. Has reconfigure been run?"
    Kernel.exit 1
  end

  warning_message = <<~EOS
    NOTE: This command fetches initial root password that were either automatically
          generated or provided manually via `gitlab.rb` file during initialization
          of this GitLab instance.
          However, if this password was changed manually via UI, then the output from
          this command might not reflect current password. In that case, users must
          reset their root password following documentation available at
          https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password
  EOS
  log warning_message

  secrets = JSON.parse(File.read('/etc/gitlab/gitlab-secrets.json'))
  password = secrets&.dig('gitlab_rails', 'initial_root_password')

  unless password
    log "Initial password neither automatically generated nor provided via `gitlab.rb`. To reset password, follow instructions at https://docs.gitlab.com/ee/security/reset_user_password.html#reset-your-root-password."
    Kernel.exit 1
  end

  log "\n\nPassword: #{password}"
end
