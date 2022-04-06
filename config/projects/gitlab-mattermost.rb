require "#{Omnibus::Config.project_root}/lib/gitlab/util"
require "#{Omnibus::Config.project_root}/lib/gitlab/build/info"

name 'gitlab-mattermost'
description 'GitLab Mattermost'

maintainer 'GitLab, Inc. <support@gitlab.com>'
homepage 'https://about.gitlab.com/'

license 'MIT'
license_compiled_output false

install_dir '/opt/gitlab'

dependency 'mattermost'

# For now, we are mimicing the version of the GitLab packages
build_version Build::Info.semver_version
build_iteration Gitlab::BuildIteration.new.build_iteration

# Enable signing packages
package :rpm do
  vendor 'GitLab, Inc. <support@gitlab.com>'
  signing_passphrase Gitlab::Util.get_env('GPG_PASSPHRASE')
end

package :deb do
  vendor 'GitLab, Inc. <support@gitlab.com>'
  signing_passphrase Gitlab::Util.get_env('GPG_PASSPHRASE')
end

resources_path "#{Omnibus::Config.project_root}/resources"

license_file_path 'gitlab-mattermost-LICENSE'
json_manifest_path '/opt/gitlab/gitlab-mattermost-version-manifest.json'
text_manifest_path '/opt/gitlab/gitlab-mattermost-version-manifest.txt'
dependency_license_json_path '/opt/gitlab/gitlab-mattermost-dependency_licenses.json'

package_user 'root'
package_group 'root'
