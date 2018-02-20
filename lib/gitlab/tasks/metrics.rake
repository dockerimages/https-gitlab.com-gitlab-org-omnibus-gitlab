require_relative "../build/check.rb"
require_relative "../build/info.rb"
require_relative "../build/metrics.rb"

namespace :metrics do
  desc "Upgrade gitlab-ee package"
  task :upgrade_package do
    if Build::Metrics.should_upgrade?
      Build::Metrics.configure_gitlab_repo
      Build::Metrics.install_package(Build::Metrics.previous_version, upgrade: false)
      Build::Metrics.install_package(Info.release_version, upgrade: true)
      Build::Metrics.parse_and_extract_log
    end
  end
end
