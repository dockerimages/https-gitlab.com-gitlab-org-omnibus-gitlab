postgresql_pgpass 'git' do
  database_username 'gitlab'
  database_password 'mypassword'
  database_host '10.0.0.1'
  database_port '1234'
  database 'gitlabhq_production'
end
