require_relative '../build/assets.rb'
require_relative '../build/check.rb'
require_relative '../build/info.rb'

namespace :assets do
  desc 'Fetch the assets from the upstream pipeline'
  task :fetch do
    version = Build::Info.gitlab_version
    type = Build::Info.package
    Build::Assets.fetch(ENV['ARTIFACT_FILE'], type, version)
  end

  desc 'Decompress the artifacts zip'
  task :decompress do
    sh "unzip -qo #{ENV['ARTIFACT_FILE']} 'public/*' -d #{ENV['ASSETS_DESTINATION']}"
  end

  desc 'Fetch and install the artifacts'
  task install: [:fetch, :decompress]
end
