require 'fileutils'
require_relative 'util'

module GitlabCtl
  class SetRootPassword
    class << self
      def execute!(username: 'root')
        password = clean_password(GitlabCtl::Util.get_password)

        status = set_password(username, password)

        if status.error?
          warn "Failed to update password."
          warn status.stdout if status.stdout
          warn status.stderr if status.stderr

          Kernel.exit 1
        else
          $stdout.puts "Password updated successfully."
        end

      rescue GitlabCtl::Errors::PasswordMismatch
        warn "Passwords do not match."
        Kernel.exit 1
      end

      def clean_password(password)
        # If user provided password contains a backslash or a single quote, we
        # double-escape it. We are double escaping so that it works properly
        # when put in the script file and is read by gitlab-rails runner.
        password.gsub("\\", '\\\\\\').gsub("'", "\\\\'")
      end

      def get_file_owner_and_group
        node_attributes = GitlabCtl::Util.get_node_attributes
        [node_attributes['gitlab']['user']['username'], node_attributes['gitlab']['user']['group']]
      rescue GitlabCtl::Errors::NodeError
        warn "Unable to get username and group of user to own script file. Please ensure `sudo gitlab-ctl reconfigure` succeeds before first."
        Kernel.exit 1
      end

      def password_update_script(username, password)
        <<~EOF
          user = User.find_by_username('#{username}')
          unless user
            warn "Unable to find user with username '#{username}'."
            Kernel.exit 1
          end

          user.update!(password: '#{password}', password_confirmation: '#{password}', password_automatically_set: false)
        EOF
      end

      def set_password(username, password)
        gitlab_user, gitlab_group = get_file_owner_and_group

        filename, status = Tempfile.open('gitlab-reset-password-script-') do |script_file|
          FileUtils.chown(gitlab_user, gitlab_group, script_file.path)

          script_file << password_update_script(username, password)
          script_file.flush

          puts "Attempting to reset password of user with username '#{username}'. This might take a few moments."
          status = GitlabCtl::Util.run_command("/opt/gitlab/bin/gitlab-rails runner #{script_file.path}")

          [script_file.path, status]
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
