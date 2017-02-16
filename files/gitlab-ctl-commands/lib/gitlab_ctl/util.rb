require 'mixlib/shellout'

module GitlabCtl
  module Util
    class <<self
      def get_command_output(command)
        shell_out = Mixlib::ShellOut.new(command)
        shell_out.run_command
        begin
          shell_out.error!
        rescue Mixlib::ShellOut::ShellCommandFailed
          raise GitlabCtl::Errors::ExecutionError.new(
            command, shell_out.stdout, shell_out.stderr
          )
        end
        shell_out.stdout
      end

      def get_gitlab_rb_value(section, value)
        File.readlines('/etc/gitlab/gitlab.rb').grep(
          %r{^#{section}\['#{value}'\]}
        ).first.split('=').last.strip
      end
    end
  end
end
