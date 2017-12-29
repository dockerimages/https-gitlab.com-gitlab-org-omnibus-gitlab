[node['gitlab']['nginx']['ssl_directory'], node['gitlab']['letsencrypt']['wwwroot']].each do |dir|
  directory dir do
    user 'root'
    group 'root'
    mode 0600
  end
end

node.set['acme']['endpoint'] = 'https://acme-staging.api.letsencrypt.org/'
node.set['acme']['contact'] = node['gitlab']['letsencrypt']['contact']

acme_certificate URI(node['gitlab']['external-url']).host do
  crt node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  chain node['gitlab']['letsencrypt']['chain']
  wwwroot node['gitlab']['letsencrypt']['wwwroot']
end
