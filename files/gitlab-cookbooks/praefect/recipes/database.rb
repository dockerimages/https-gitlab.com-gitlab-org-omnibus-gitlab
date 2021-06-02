pg_helper = PgHelper.new(node)
praefect_helper = PraefectHelper.new(node)

if praefect_helper.create_database?
  postgresql_database node['praefect']['sql_database'] do
    owner node['praefect']['pgbouncer_user']
    helper pg_helper
  end
end
