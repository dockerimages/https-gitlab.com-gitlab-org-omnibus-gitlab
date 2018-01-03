resource_name :nginx_site

property :hostname, String, name_property: true
property :template, String
property :cookbook, String
property :variables, Hash, default: {}

action :enable do
  declare_resource(:template, "/var/opt/gitlab/nginx/conf/sites.d/#{new_resource.hostname}.conf") do
    source new_resource.template
    cookbook new_resource.cookbook
    variables(new_resource.variables)
  end

  execute 'reload nginx' do
    command 'gitlab-ctl hup nginx'
  end
end

action :disable do
  file "/var/opt/gitlab/nginx/conf/sites.d/#{new_resource.name}.conf" do
    action :delete
  end

  execute 'reload nginx' do
    command 'gitlab-ctl hup nginx'
  end
end
