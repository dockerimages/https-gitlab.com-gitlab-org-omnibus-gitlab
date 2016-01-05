#
# Cookbook Name:: kitchen-prepare
# Recipe:: default
#
# Copyright 2016, GitLab B.V.
#
# All rights reserved - Do Not Redistribute
#
package 'git'

if node['platform'] =~ /centos/
  [
    'selinux-policy-devel',
    'cronie'
  ].each do |pkg|
    package pkg
  end
else
  package 'cron'
end

# Stub directories that will be created by installing the package
[
  "/etc/gitlab",
  "/opt/gitlab/embedded/service/",
  "/opt/gitlab/embedded/bin/",
  "/opt/gitlab/sv",
  "/opt/gitlab/init/",
  "/opt/gitlab/bin/",
  "/opt/gitlab/service",
  "/var/opt/gitlab/postgresql/data"
].each do |dir|
  directory dir do
    recursive true
  end
end

# Stub services which will be called during cookbook run
%w( redis postgresql sidekiq unicorn gitlab-workhorse nginx logrotate svlogd ).each do |service|
  [
    "/opt/gitlab/sv/#{service}/supervise",
    "/opt/gitlab/sv/#{service}/log/supervise/"
  ].each do |dir|
    directory dir do
      recursive true
    end
  end

  execute "create a named pipe for #{service}" do
    command "mkfifo /opt/gitlab/sv/#{service}/supervise/ok"
    not_if { File.exists?("/opt/gitlab/sv/#{service}/supervise/ok") }
  end
end

# Stub files that will be checked/called during the cookbook run
# and assume they work
[
  "/var/opt/gitlab/postgresql/data/PG_VERSION",
  "/opt/gitlab/bin/gitlab-rake",
  "/opt/gitlab/bin/gitlab-ctl",
  "/opt/gitlab/embedded/bin/chpst"
].each do |file|
  file file do
    mode 0755
    content "exit 0"
  end
end

# Supply minimal gitlab.rb file
cookbook_file "/etc/gitlab/gitlab.rb"

# Clone the required projects
git "clone gitlab-rails" do
  destination "/opt/gitlab/embedded/service/gitlab-rails"
  repository "https://github.com/gitlabhq/gitlabhq.git"
  enable_checkout true # checkout master
end

git "clone gitlab-shell" do
  destination "/opt/gitlab/embedded/service/gitlab-shell"
  repository "https://github.com/gitlabhq/gitlab-shell.git"
  enable_checkout true # checkout master
end

git "clone mattermost" do
  destination "/opt/gitlab/embedded/service/mattermost"
  repository "https://github.com/mattermost/platform.git"
  enable_checkout true # checkout master
end

# Remove directories which are deleted during build
[
  "/opt/gitlab/embedded/service/gitlab-rails/tmp",
  "/opt/gitlab/embedded/service/gitlab-rails/log"
].each do |dir|
  directory dir do
    recursive true
    action :delete
  end
end

file "/etc/inittab" do
  content "'CS:123456:respawn:/opt/gitlab/embedded/bin/runsvdir-start'"
end
