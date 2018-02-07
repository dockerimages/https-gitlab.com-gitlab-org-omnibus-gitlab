require_relative "../build/check.rb"
require_relative "../build/info.rb"
require_relative "../build/metrics.rb"

namespace :metrics do
  desc "Upgrade gitlab-ee package"
  task :upgrade_package do
    puts "Version to be installed is #{Build::Info.release_version}"
    Build::Metrics.install_package if Build::Metrics.should_upgrade?
  end
end
