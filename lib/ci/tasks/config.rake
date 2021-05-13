require_relative '../config'

namespace :ci do
  namespace :config do
    desc "Generate CI configuration"
    task :generate do
      config = Ci::Config.new
      config.execute

      config.print_pipeline if Gitlab::Util.get_env('DRY_RUN') == 'true'

      config.write_pipeline
    end
  end
end
