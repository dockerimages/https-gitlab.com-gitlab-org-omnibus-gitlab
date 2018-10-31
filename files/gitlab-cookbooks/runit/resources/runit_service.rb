#
# Copyright 2008-2009, Opscode, Inc.
# Copyright:: Copyright (c) 2018 GitLab Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource_name :runit_service
provides :runit_service

actions :enable, :disable
default_action :create

property :directory, [String, nil], default: nil
property :finish_script, [true, false], default: false
property :control, Array, default: []
property :run_restart, [true, false], default: false
property :active_directory, [String, nil], default: nil
property :init_script_template, [String, nil], default: nil
property :owner, [Integer, String], default: "root"
property :group, [Integer, String], default: "root"
property :template_name, [String, nil], default: nil
property :start_command, String, default: "start"
property :stop_command, String, default: "stop"
property :restart_command, [Integer, String], default: "restart"
property :status_command, String, default: "status"
property :options, Hash, default: {}
property :log_options, Hash, default: {}
property :env, Hash, default: {}
property :down, [true, false], default: false
property :supervisor_owner, [Integer, String, nil], default: nil
property :supervisor_group, [Integer, String, nil], default: nil
property :cookbook, [String, nil], default: nil

action_class do
  def get_sv_directory_name
    sv_directory = new_resource.directory || node[:runit][:sv_dir]
    "#{sv_directory}/#{new_resource.name}"
  end

  def get_active_service_directory
    new_resource.active_directory || node[:runit][:service_dir]
  end

  def get_active_service_directory_name
    "#{get_active_service_directory}/#{new_resource.name}"
  end

  def get_service_options
    opts = new_resource.options.dup
    opts[:env_dir] = "#{sv_dir_name}/env" unless new_resource.env.empty?
    opts
  end
end

action :enable do
  include_recipe "runit"

  omnibus_helper = OmnibusHelper.new(node)
  sv_dir_name = get_sv_directory_name
  active_service_directory = get_active_service_directory
  active_service_dir_name = get_active_service_directory_name
  service_options = get_service_options
  service_template_name = new_resource.template_name || new_resource.name

  directory sv_dir_name do
    owner new_resource.owner
    group new_resource.group
    mode 0755
    action :create
  end

  directory "#{sv_dir_name}/log" do
    owner new_resource.owner
    group new_resource.group
    mode 0755
    action :create
  end

  directory "#{sv_dir_name}/log/main" do
    owner new_resource.owner
    group new_resource.group
    mode 0755
    action :create
  end

  template "#{sv_dir_name}/run" do
    owner new_resource.owner
    group new_resource.group
    mode 0755
    source "sv-#{service_template_name}-run.erb"
    cookbook new_resource.cookbook if new_resource.cookbook
    variables options: service_options if service_options.respond_to?(:has_key?)
  end

  template "#{sv_dir_name}/log/run" do
    owner new_resource.owner
    group new_resource.group
    mode 0755
    source "sv-#{service_template_name}-log-run.erb"
    cookbook new_resource.cookbook if new_resource.cookbook
    variables options: service_options if service_options.respond_to?(:has_key?)
    notifies :create, "ruby_block[restart #{new_resource.name} svlogd configuration]"
  end

  template ::File.join(service_options[:log_directory], "config") do
    owner new_resource.owner
    group new_resource.group
    source "sv-#{service_template_name}-log-config.erb"
    cookbook new_resource.cookbook if new_resource.cookbook
    variables new_resource.log_options
    notifies :create, "ruby_block[reload #{new_resource.name} svlogd configuration]"
  end

  ruby_block "reload #{new_resource.name} svlogd configuration" do
    block do
      ::File.open(::File.join(sv_dir_name, "log/supervise/control"), "w") do |control|
        control.print "h"
      end
    end
    action :nothing
  end

  ruby_block "restart #{new_resource.name} svlogd configuration" do
    block do
      ::File.open(::File.join(sv_dir_name, "log/supervise/control"), "w") do |control|
        control.print "k"
      end
    end
    action :nothing
  end

  if new_resource.down
    file "#{sv_dir_name}/down" do
      mode "0644"
    end
  else
    file "#{sv_dir_name}/down" do
      action :delete
    end
  end

  unless new_resource.env.empty?
    directory "#{sv_dir_name}/env" do
      mode 0755
      action :create
    end

    new_resource.env.each do |var, value|
      file "#{sv_dir_name}/env/#{var}" do
        content value
      end
    end
  end

  if new_resource.finish_script
    template "#{sv_dir_name}/finish" do
      owner new_resource.owner
      group new_resource.group
      mode 0755
      source "sv-#{service_template_name}-finish.erb"
      cookbook new_resource.cookbook if new_resource.cookbook
      if service_options.respond_to?(:has_key?)
        variables options: service_options
      end
    end
  end

  unless new_resource.control.empty?
    directory "#{sv_dir_name}/control" do
      owner new_resource.owner
      group new_resource.group
      mode 0755
      action :create
    end

    new_resource.control.each do |signal|
      template "#{sv_dir_name}/control/#{signal}" do
        owner new_resource.owner
        group new_resource.group
        mode 0755
        source "sv-#{service_template_name}-control-#{signal}.erb"
        cookbook new_resource.cookbook if new_resource.cookbook
        if service_options.respond_to?(:has_key?)
          variables options: service_options
        end
      end
    end
  end

  if new_resource.init_script_template
    template "/opt/gitlab/init/#{new_resource.name}" do
      owner new_resource.owner
      group new_resource.group
      mode 0755
      source new_resource.init_script_template
      if service_options.respond_to?(:has_key?)
        variables options: service_options
      end
    end
  elsif active_service_directory == node[:runit][:service_dir]
    link "/opt/gitlab/init/#{new_resource.name}" do
      to node[:runit][:sv_bin]
    end
  end

  unless node[:platform] == "gentoo"
    link active_active_service_dir_name do
      to sv_dir_name
    end
  end

  ruby_block "supervise_#{new_resource.name}_sleep" do
    block do
      Chef::Log.debug("Waiting until named pipe #{sv_dir_name}/supervise/ok exists.")
      until ::FileTest.pipe?("#{sv_dir_name}/supervise/ok")
        sleep 1
        Chef::Log.debug(".")
      end
    end
    not_if { ::FileTest.pipe?("#{sv_dir_name}/supervise/ok") }
  end

  directory "#{sv_dir_name}/supervise" do
    mode 0755
  end

  directory "#{sv_dir_name}/log/supervise" do
    mode 0755
  end

  supervisor_owner = new_resource.supervisor_owner || 'root'
  supervisor_group = new_resource.supervisor_group || 'root'
  %w(ok control).each do |fl|
    file "#{sv_dir_name}/supervise/#{fl}" do
      owner supervisor_owner
      group supervisor_group
      not_if { new_resource.supervisor_owner.nil? || new_resource.supervisor_group.nil? }
      only_if { !omnibus_helper.expected_owner?(name, supervisor_owner, supervisor_group) }
      action :touch
    end

    file "#{sv_dir_name}/log/supervise/#{fl}" do
      owner supervisor_owner
      group supervisor_group
      not_if { new_resource.supervisor_owner.nil? || new_resource.supervisor_group.nil? }
      only_if { !omnibus_helper.expected_owner?(name, supervisor_owner, supervisor_group) }
      action :touch
    end
  end

  service new_resource.name do
    control_cmd = node[:runit][:sv_bin]
    if new_resource.owner
      control_cmd = "#{node[:runit][:chpst_bin]} -u #{new_resource.owner}:#{new_resource.group} #{control_cmd}"
    end
    provider Chef::Provider::Service::Simple
    supports restart: true, status: true
    start_command "#{control_cmd} #{new_resource.start_command} #{active_service_dir_name}"
    stop_command "#{control_cmd} #{new_resource.stop_command} #{active_service_dir_name}"
    restart_command "#{control_cmd} #{new_resource.restart_command} #{active_service_dir_name}"
    status_command "#{control_cmd} #{new_resource.status_command} #{active_service_dir_name}"
    if new_resource.run_restart && omnibus_helper.should_notify?(new_resource.name)
      subscribes :restart, resources(template: "#{sv_dir_name}/run"), :delayed
    end
    action :nothing
  end
end

action :disable do
  active_service_dir_name = get_active_service_directory_name
  sv_dir_name = get_sv_directory_name

  link active_service_dir_name do
    action :delete
  end

  directory sv_dir_name do
    recursive true
    action :delete
  end
end
