require_relative "../build/check.rb"
require_relative "../build/info.rb"
require_relative "../build/metrics.rb"

namespace :metrics do
  desc "Upgrade gitlab-ee package"
  task :upgrade_package do
    if Build::Check.is_patch_release?
      puts "Patch release. Not upgrading."
    else
      puts "Version to be installed is #{Build::Info.release_version}"
      Build::Metrics.install_package unless Build::Check.is_patch_release?
    end
  end
end
