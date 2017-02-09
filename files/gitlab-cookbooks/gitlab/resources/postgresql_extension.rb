property :extension, String
property :database, String
property :user, String

action :enable do
  execute "enable #{extension} extension" do
    command %(/opt/gitlab/bin/gitlab-psql -d #{database} -c "CREATE EXTENSION IF NOT EXISTS #{extension};")
    user user
    retries 20
    action :nothing
  end
end

action :disable do
end
