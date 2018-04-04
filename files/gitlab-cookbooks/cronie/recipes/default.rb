directory "/opt/gitlab/embedded/var/spool/cron" do
  recursive true
  owner "root"
end

directory "/opt/gitlab/embedded/etc/cron.d" do
  recursive true
  owner "root"
end

runit_service "cronie" do
  owner "root"
  group "root"
  options(
    {
      log_directory: node['cronie']['log_directory']
    })
  log_options node['cronie'].to_hash
end
