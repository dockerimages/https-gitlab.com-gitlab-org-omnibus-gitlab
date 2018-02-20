require_relative "info.rb"

module Build
  class Metrics
    class << self
      def configure_gitlab_repo
        system("sudo apt-get update && sudo apt-get install -y curl openssh-server ca-certificates")
        system("curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash")
      end

      def install_package(version, upgrade: false)
        system("sudo EXTERNAL_URL='http://gitlab.example.com' apt-get -y install gitlab-ee=#{version}")
        return if upgrade
        system("/opt/gitlab/embedded/bin/runsvdir-start &")
        system("sudo gitlab-ctl reconfigure")
      end

      def should_upgrade?
        # We need not update if the tag is either from an older version series or a
        # patch release or a CE version.
        status = true
        if !Build::Check.is_ee?
          puts "Not an EE package. Not upgrading."
          status = false
        elsif !Build::Check.is_an_upgrade?
          puts "Not the latest package. Not upgrading."
          status = false
        elsif Build::Check.is_patch_release?
          puts "Not a major/minor release. Not upgrading."
          status = false
        elsif Build::Check.add_rc_tag?
          puts "RC release. Not upgrading."
          status = false
        end
        status
      end

      def previous_version
        # Get the second latest git tag
        previous_tag = Info.latest_stable_tag(2)
        previous_tag.tr("+", "-")
      end

      def get_latest_log
        # Getting last block from log to a separate file
        log_location = "/var/log/apt/term.log"
        system("tac #{log_location} | sed '/^Log started/q' | tac > /tmp/upgrade.log")
      end

      def calculate_duration
        get_latest_log
        start_string = File.open("/tmp/upgrade.log").grep(/Log started/)[0].strip.gsub("Log started: ", "")
        end_string = File.open("/tmp/upgrade.log").grep(/Log ended/)[0].strip.gsub("Log ended: ", "")
        start_time = DateTime.strptime(start_string, "%Y-%m-%d  %H:%M:%S")
        end_time = DateTime.strptime(end_string, "%Y-%m-%d  %H:%M:%S")
        # Return duration in seconds
        ((end_time - start_time) * 24 * 60 * 60).to_i
      end
    end
  end
end
