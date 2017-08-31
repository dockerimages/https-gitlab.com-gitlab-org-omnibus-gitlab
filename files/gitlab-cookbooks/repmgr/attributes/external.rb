default['gitlab']['postgresql']['custom_pg_hba_entries']['repmgr'] = []
default['gitlab']['logrotate']['services'] << 'repmgrd'
