name "gitlab-base"
maintainer "GitLab.com"
maintainer_email "support@gitlab.com"
license "Apache 2.0"
description "Base Omnibus structure"
long_description "Base Omnibus structure"
version "0.0.1"
recipe "gitlab-base", "Bootstraps Omnibus structure"

supports "ubuntu"

depends 'package'
depends 'logrotate'

# Optional dependency Support
# We want to make cookbooks dependent only if they are present on disk
# require File.join(File.dirname(__FILE__ ), 'libraries', 'dependency_helper')
# dependency_helper = ::DependencyHelper.new
#
# # Optional dependencies
# depends 'postgresql' if dependency_helper.cookbook_present?('postgresql')
# depends 'prometheus' if dependency_helper.cookbook_present?('prometheus')
# depends 'redis' if dependency_helper.cookbook_present?('redis')
# depends 'registry' if dependency_helper.cookbook_present?('registry')
# depends 'mattermost' if dependency_helper.cookbook_present?('mattermost')
# depends 'consul' if dependency_helper.cookbook_present?('consul')
# depends 'gitaly' if dependency_helper.cookbook_present?('gitaly')
# depends 'letsencrypt' if dependency_helper.cookbook_present?('letsencrypt')
# depends 'nginx' if dependency_helper.cookbook_present?('nginx')
