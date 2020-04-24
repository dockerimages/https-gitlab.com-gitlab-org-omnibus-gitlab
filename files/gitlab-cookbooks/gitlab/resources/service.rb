property :control, Array, default: []
property :service, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :options, Hash, default: {}
property :supervisor_owner, String
property :supervisor_group, String
property :log_options, Hash
property :restart_on_update, [true, false], default: true
property :restart_command, String
property :finish, [true, false], default: false

# TODO: ensure only one of these are set
# property :down, [true, false]
property :start_down, [true, false]

property :template_name, String

action :enable do
  alias down start_down

  runit_service new_resource.service do
    control new_resource.control
    start_down new_resource.start_down
    owner new_resource.owner
    group new_resource.group
    options new_resource.options unless new_resource.options.empty?
    supervisor_owner new_resource.supervisor_owner
    supervisor_group new_resource.supervisor_group
    unless new_resource.log_options.nil?
      log_size new_resource.log_options[:svlogd_size]
      log_num new_resource.log_options[:svlogd_num]
      log_timeout new_resource.log_options[:svlogd_timeout]
      log_prefix new_resource.log_options[:svlogd_prefix]
      log_processor new_resource.log_options[:svlogd_filter]
      log_socket new_resource.log_options[:svlogd_udp]
    end
    restart_on_update new_resource.restart_on_update
    run_template_name new_resource.template_name unless new_resource.template_name.nil?
    finish new_resource.finish
  end

end

action :disable do
  runit_service new_resource.service do
    action :disable
  end
end

action :restart do
  runit_service new_resource.service do
    action :restart
  end
end
