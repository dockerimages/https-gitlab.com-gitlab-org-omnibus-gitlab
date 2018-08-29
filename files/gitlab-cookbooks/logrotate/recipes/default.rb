# Enable or disable service based on attribute flags
if node['gitlab']['logrotate']['enable']
  include_recipe 'logrotate::enable'
else
  include_recipe 'logrotate::disable'
end
