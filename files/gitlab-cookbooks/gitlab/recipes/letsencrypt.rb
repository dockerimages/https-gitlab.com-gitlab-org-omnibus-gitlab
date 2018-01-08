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

acme_ssl_certificate node['gitlab']['nginx']['ssl_certificate'] do
  cn site
  key node['gitlab']['nginx']['ssl_certificate_key']
  output :crt
  min_validity 30
  webserver :nginx
  owner 'gitlab-www'
  endpoint 'https://acme-staging.api.letsencrypt.org/'
  contact node['gitlab']['letsencrypt']['contact']
end
