# All tasks in files placed in lib/gitlab/tasks ending in .rake will be loaded
# automatically
require 'knapsack'
require_relative 'lib/ci/pipeline'

Rake.add_rakelib 'lib/gitlab/tasks'
Knapsack.load_tasks

namespace :ci do
  desc "Generate CI config"
  task :generate_config do
    CI::Pipeline.new.generate_ci_config
  end
end
