require "#{Omnibus::Config.project_root}/lib/gitlab/build_iteration"
require "#{Omnibus::Config.project_root}/lib/gitlab/build/info"
require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'gitlab-rails-gems-test'
description 'Test install of the Gems from gitLab-rails'

maintainer 'GitLab, Inc. <support@gitlab.com>'
homepage 'https://about.gitlab.com/'

license 'MIT'
license_compiled_output true

dependency 'gitlab-rails-gems'

build_version Build::Info.semver_version
build_iteration Gitlab::BuildIteration.new.build_iteration

install_dir '/opt/gitlab-rails-gems-test'
