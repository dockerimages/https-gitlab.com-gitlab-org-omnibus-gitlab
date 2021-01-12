require 'fileutils'
require_relative 'util'

module GitlabCtl
  class SetRootPassword
    class << self
      def execute!(username: 'root')
        password = GitlabCtl::Util.get_password

        status = set_password(username, password)

        raise if status.error?

        puts "Password updated successfully."

      rescue RuntimeError
        warn "Failed to update password."
        warn status.stdout
        warn status.stderr
        Kernel.exit 1
      rescue GitlabCtl::Errors::PasswordMismatch
        warn "Passwords do not match."
        Kernel.exit 1
      end

      def get_file_owner_and_group
        node_attributes = GitlabCtl::Util.get_node_attributes
        [node_attributes['gitlab']['user']['username'], node_attributes['gitlab']['user']['group']]
      rescue GitlabCtl::Errors::NodeError
        warn "Unable to get username and group of user to own script file. Please ensure `sudo gitlab-ctl reconfigure` succeeds before first."
        Kernel.exit 1
      end

      def set_password(username, password)
        gitlab_user, gitlab_group = get_file_owner_and_group

        filename, status = Tempfile.open('gitlab-reset-password-script-') do |credentials_file|
          FileUtils.chown(gitlab_user, gitlab_group, credentials_file.path)

          credentials_file << username << "\n" << password
          credentials_file.flush

          puts "Attempting to reset password of user with username '#{username}'. This might take a few moments."
          status = GitlabCtl::Util.run_command("/opt/gitlab/bin/gitlab-rails runner /opt/gitlab/embedded/service/omnibus-ctl/scripts/set_user_password.rb #{credentials_file.path}")

          [credentials_file.path, status]
        end

        status
      ensure
        FileUtils.rm_rf(filename)
      end

      def parse_options(args)
        options = {
          username: 'root'
        }
        OptionParser.new do |opts|
          opts.on('-uUSERNAME', '--username=USERNAME', 'Specify username of account to change password.') do |u|
            options[:username] = u
          end
        end.parse!(args)

        options
      end
    end
  end
end
