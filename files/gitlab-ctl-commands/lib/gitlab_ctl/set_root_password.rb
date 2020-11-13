require 'fileutils'
require_relative 'util'

module GitlabCtl
  class SetRootPassword
    def initialize(username = 'root')
      @username = username

      node_attributes = GitlabCtl::Util.get_node_attributes
      @gitlab_user = node_attributes['gitlab']['user']['username']
      @gitlab_group = node_attributes['gitlab']['user']['group']
    end

    def execute
      get_password
      clean_password
      set_password
    end

    def get_password
      @password = GitlabCtl::Util.get_password
    rescue GitlabCtl::Errors::PasswordMismatch
      warn "Passwords do not match."
      Kernel.exit 1
    end

    def clean_password
      # If user provided password contains an unescaped single quote, we escape it.
      @password.gsub!("'", "\\\\'") if @password.include?("'") && !@password.include?("\\'")
    end

    def set_password
      script_path = populate_script

      puts "Attempting to reset password of user with username '#{@username}'. This might take a few moments."
      status = GitlabCtl::Util.run_command("/opt/gitlab/bin/gitlab-rails runner #{script_path}")

      if status.error?
        warn "Failed to update password."
        warn status.stdout
        warn status.stderr
        Kernel.exit 1
      else
        $stdout.puts "Password updated successfully."
      end
    end

    def populate_script
      script_file = Tempfile.new('gitlab-reset-password-script-')
      FileUtils.chown(@gitlab_user, @gitlab_group, script_file.path)

      script_file << <<~EOF
        user = User.find_by_username('#{@username}')
        raise "Unable to find user with username '#{@username}'." unless user

        user.update!(password: '#{@password}', password_confirmation: '#{@password}', password_automatically_set: false)
      EOF

      script_file.flush

      script_file.path
    end

    class << self
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
