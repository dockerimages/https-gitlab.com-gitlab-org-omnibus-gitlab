property :host_user, name_property: true
property :database_username, String, default: lazy { node['gitlab']['postgresql']['sql_user'] }
property :database_password
property :database_host, String, default: lazy { node['gitlab']['postgresql']['host'] }
property :database_port, default: lazy { node['gitlab']['postgresql']['port'] }
property :database, String, default: '*'
property :filename, String, default: '.pgpass'

action :create do
  pgpass = Pgpass.new(username: new_resource.database_username,
                      password: new_resource.database_password,
                      hostname: new_resource.database_host,
                      port: new_resource.database_port,
                      database: new_resource.database,
                      host_user: new_resource.host_user,
                      filename: new_resource.filename)

  file pgpass.filename do
    content pgpass.render
    owner pgpass.userinfo.uid
    group pgpass.userinfo.gid
    mode 0600
    sensitive true
  end
end

action :delete do
  pgpass = Pgpass.new(username: new_resource.database_username,
                      password: new_resource.database_password,
                      host_user: new_resource.host_user)

  file pgpass.filename do
    action :delete
  end
end
