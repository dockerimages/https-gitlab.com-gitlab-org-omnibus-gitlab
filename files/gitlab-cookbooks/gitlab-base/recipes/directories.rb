# Default location of install-dir is /opt/gitlab/. This path is set during build time.
# DO NOT change this value unless you are building your own GitLab packages
install_dir = node['package']['install-dir']
ENV['PATH'] = "#{install_dir}/bin:#{install_dir}/embedded/bin:#{ENV['PATH']}"

OmnibusHelper.check_deprecations

directory "/etc/gitlab" do
  owner "root"
  group "root"
  mode "0775"
  only_if { node['gitlab']['manage-storage-directories']['manage_etc'] }
end.run_action(:create)

if File.exist?("/var/opt/gitlab/bootstrapped")
  node.default['gitlab']['bootstrap']['enable'] = false
end

directory "Create /var/opt/gitlab" do
  path "/var/opt/gitlab"
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

directory "#{install_dir}/embedded/etc" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

# Install our runit instance
include_recipe "runit"
