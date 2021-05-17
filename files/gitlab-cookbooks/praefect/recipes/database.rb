pg_helper = PgHelper.new(node)
praefect_helper = PraefectHelper.new(node)

if praefect_helper.create_database?
  database_owner = node['praefect']['sql_user'] || node['praefect']['pgbouncer_user']
  postgresql_database node['praefect']['sql_database'] do
    owner database_owner unless database_owner.nil?
    helper pg_helper
  end
end
