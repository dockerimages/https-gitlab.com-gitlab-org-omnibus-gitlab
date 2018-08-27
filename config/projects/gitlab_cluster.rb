require "#{Omnibus::Config.project_root}/lib/gitlab/build_iteration"
require "#{Omnibus::Config.project_root}/lib/gitlab/build/info"
require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'gitlab-cluster'
description 'GitLab Cluster'
replace 'gitlab-ce'
replace 'gitlab-ee'
replace 'gitlab'
conflict 'gitlab-ce'
conflict 'gitlab-ee'
conflict 'gitlab'

maintainer 'GitLab, Inc. <support@gitlab.com>'
homepage 'https://about.gitlab.com/'

license 'MIT'
license_compiled_output true

install_dir '/opt/gitlab'

# This is a hack to make a distinction between nightly versions
# See https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1500
#
# This will be resolved as part of
# https://gitlab.com/gitlab-org/omnibus-gitlab/issues/1007
#
# Also check lib/gitlab/build.rb for Docker version forming
build_version Build::Info.semver_version
build_iteration Gitlab::BuildIteration.new.build_iteration

runtime_dependency 'policycoreutils-python' if rhel?

dependency 'mixlib-log'
dependency 'chef-zero'
dependency 'awesome_print'
dependency 'ohai'
dependency 'chef-gem'
dependency 'remote-syslog'
dependency 'logrotate'
dependency 'runit'
dependency 'gitlab-ctl-ee'
dependency 'gitlab-ctl'
dependency 'gitlab-scripts'
dependency 'package-scripts'
dependency 'consul'
dependency 'gitlab-cluster-cookbooks'

exclude "\.git*"
exclude "bundler\/git"

# don't ship static libraries or header files
exclude 'embedded/lib/*.a'
exclude 'embedded/lib/*.la'
exclude 'embedded/include'

# exclude manpages and documentation
exclude 'embedded/man'
exclude 'embedded/share/doc'
exclude 'embedded/share/gtk-doc'
exclude 'embedded/share/info'
exclude 'embedded/share/man'

# exclude rubygems build cache
# Revisit this path as part of
# https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3414
exclude 'embedded/lib/ruby/gems/2.4.0/cache'

# Our package scripts are generated from .erb files,
# so we will grab them from an excluded folder
package_scripts_path "#{install_dir}/.package_util/package-scripts"
exclude '.package_util'

package_user 'root'
package_group 'root'
