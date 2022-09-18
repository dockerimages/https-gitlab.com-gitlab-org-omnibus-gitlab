name "gitlab"
maintainer "GitLab.com"
maintainer_email "support@gitlab.com"
license "Apache 2.0"
description "Install and configure GitLab from Omnibus"
long_description "Install and configure GitLab from Omnibus"
version "0.0.1"
recipe "gitlab", "Configures GitLab from Omnibus"

supports "ubuntu"

dependencies = %w[
  package
  logrotate
  postgresql
  redis
  monitoring
  registry
  mattermost
  consul
  gitaly
  praefect
  gitlab-kas
  gitlab-pages
  letsencrypt
  nginx
]

dependencies.each do |dep|
  depends dep.to_s if Dir.exist?("/opt/gitlab/embedded/cookbooks/#{dep}")
end
