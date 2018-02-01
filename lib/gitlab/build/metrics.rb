require_relative "info.rb"

module Build
  class Metrics
    class << self
      def install_package
        system("sudo apt-get update && sudo apt-get -y install gitlab-ee=#{Info.release_version}")
      end
    end
  end
end
