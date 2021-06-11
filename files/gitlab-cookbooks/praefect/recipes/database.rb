pg_helper = PgHelper.new(node)
praefect_helper = PraefectHelper.new(node)

if praefect_helper.create_database?
  postgresql_database node['praefect']['sql_database'] do
    helper pg_helper
  end
end

ruby_block 'warn geo cluster' do
  block do
    message = <<~MESSAGE
      Omnibus can not cofigure PostgreSQL database in Geo clusters.
      You need to follow manual steps to setup the PostgreSQL database for Praefect.
      Please see:
        https://docs.gitlab.com/ee/administration/gitaly/praefect.html#postgresql
    MESSAGE
    LoggingHelper.warning(message)
  end
  only_if { praefect_helper.running_in_geo? && node['praefect']['manage_database'] }
end
