require_relative "../build/check.rb"
require_relative "../build/info.rb"
require_relative "../build/metrics.rb"

namespace :metrics do
  desc "Upgrade gitlab-ee package"
  task :upgrade_package do
    # We need not update if the tag is either from an older version series or a
    # patch release.
    if Build::Check.is_ee? && Build::Check.is_an_upgrade? && !Build::Check.is_patch_release?
      puts "Version to be installed is #{Build::Info.release_version}"
      Build::Metrics.install_package unless Build::Check.is_patch_release?
    else
      puts "Not the latest EE version. Not upgrading."
    end
  end
end
