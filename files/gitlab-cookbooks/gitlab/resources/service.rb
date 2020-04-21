property :service, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :options, Hash, default: {}
property :supervisor_owner, String
property :supervisor_group, String
property :log_options, Hash

action :enable do
  runit_service new_resource.service do
    owner new_resource.owner 
    group new_resource.group
    options new_resource.options unless new_resource.options.empty?
    supervisor_owner new_resource.supervisor_owner
    supervisor_group new_resource.supervisor_group
    log_size new_resource.log_options[:svlogd_size] 
    log_num new_resource.log_options[:svlogd_num]
    log_timeout new_resource.log_options[:svlogd_timeout]
    log_prefix new_resource.log_options[:svlogd_prefix]
    log_processor new_resource.log_options[:svlogd_filter]
    log_socket new_resource.log_options[:svlogd_udp]
  end
end
