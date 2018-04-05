directory node['go-crond']['log_directory'] do
  onwer "root"
end

directory node["go-crond"]["cron_d"] do
  recursive true
  owner "root"
end

runit_service "go-crond" do
  owner "root"
  group "root"
  options(
    {
      log_directory: node["go-crond"]["log_directory"],
      cron_d: node["go-crond"]["cron_d"]
    })
  log_options node["go-crond"].to_hash
end
