require 'mixlib/shellout'
require 'socket'

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

      def fqdn
        Socket.gethostbyname(Socket.gethostname).first
      end

      def get_attributes(base_path)
        # Chef creates node_file when it runs.
        # Initially it only contains the node name, but after a successful
        # reconfigure the node attributes are written to the file
        node_file = "#{base_path}/embedded/nodes/#{fqdn}.json"
        unless File.exist?(node_file)
          raise FileNotFound(
            "#{node_file} not found, has reconfigure been run yet?"
          )
        end
        data = JSON.parse(File.read(node_file))
        unless data.key?('run_list')
          raise LoadError(
            'The last reconfigure was not successful, missing data'
          )
        end
        data
      end
    end
  end
end
