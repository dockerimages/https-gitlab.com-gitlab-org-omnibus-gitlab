require_relative '../cache.rb'

desc 'Retrieve build cache from S3'

namespace :cache do
  task :fetch do
    S3Cache.new.fetch
  end
end
