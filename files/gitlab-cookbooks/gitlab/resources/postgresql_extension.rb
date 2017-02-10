resource_name :postgresql_extension

property :extension, String, name_property: true
property :database, String, required: true
property :username, String, required: true

action :enable do
  command_line = %(/opt/gitlab/bin/gitlab-psql -d #{database} -c "%{sql_command}  #{extension};")

  execute "enable #{extension} extension" do
    command command_line % { sql_command: 'CREATE EXTENSION IF NOT EXISTS' }
    user username
    retries 20
  end
end

action :disable do
  execute "disable #{extension} extension" do
    command command_line % { sql_command: 'DROP EXTENSION IF EXISTS' }
    user username
    retries 20
  end
end
