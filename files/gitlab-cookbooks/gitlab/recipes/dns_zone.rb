template node['gitlab']['dns_zone_file'] do
  source 'dns.zone.erb'
  mode 0755
end
