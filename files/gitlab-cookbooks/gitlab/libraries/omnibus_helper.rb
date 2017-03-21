require 'mixlib/shellout'
require_relative 'helper'

class OmnibusHelper
  include ShellOutHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def should_notify?(service_name)
    File.symlink?("/opt/gitlab/service/#{service_name}") && service_up?(service_name) && service_enabled?(service_name)
  end

  def not_listening?(service_name)
    File.exists?("/opt/gitlab/service/#{service_name}/down") && service_down?(service_name)
  end

  def service_enabled?(service_name)
    node['gitlab'][service_name]['enable']
  end

  def service_up?(service_name)
    cmd = "/opt/gitlab/embedded/bin/sv status #{service_name}"
    output = do_shell_out(cmd)
    output.exitstatus == 0 && output.stdout.start_with?('run: ')
  end

  def service_down?(service_name)
    !service_up?(service_name)
  end

  def user_exists?(username)
    success?("id -u #{username}")
  end

  def group_exists?(group)
    success?("getent group #{group}")
  end
# Workaround described in https://github.com/sethvargo/chefspec/issues/562#issuecomment-74120922
end unless defined?(OmnibusHelper)
