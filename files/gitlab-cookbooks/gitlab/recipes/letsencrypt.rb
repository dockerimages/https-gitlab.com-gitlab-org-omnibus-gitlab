[
  node['gitlab']['nginx']['ssl_directory'],
  node['gitlab']['nginx']['sites_directory']
].each do |dir|
  directory dir do
    user 'root'
    group 'root'
    mode 0755
    recursive true
  end
end

site = URI(node['gitlab']['external-url']).host

acme_selfsigned site do
  crt node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  chain node['gitlab']['letsencrypt']['chain']
  notifies :restart, "service[nginx]", :immediate
end

acme_ssl_certificate 'staging' do
  path "#{node['gitlab']['nginx']['ssl_certificate']}-staging"
  cn site
  key "#{node['gitlab']['nginx']['ssl_certificate_key']}-staging"
  output :crt
  min_validity 30
  webserver :nginx
  owner 'gitlab-www'
  endpoint 'https://acme-staging.api.letsencrypt.org/'
  contact [node['gitlab']['letsencrypt']['contact']]
  ssl_version :TLSv1_1
end

acme_ssl_certificate 'production' do
  path node['gitlab']['nginx']['ssl_certificate']
  cn site
  key node['gitlab']['nginx']['ssl_certificate_key']
  output :crt
  min_validity 30
  webserver :nginx
  owner 'gitlab-www'
  contact [node['gitlab']['letsencrypt']['contact']]
  ssl_version :TLSv1_1
  notifies :run, "ruby[display_message]"
  notifies :restart, "service[nginx]", :immediate
end

ruby 'display_message' do
  LoggingHelper.warning("Let's Encrypt has been configured. Please see http://foo for more information")
  action :nothing
end
