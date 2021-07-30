require_relative 'build/info'
require_relative 'util'
require_relative 'ohai_helper'

require 'google/cloud/storage'
require 'json'
require 'fileutils'

class CacheHelper
  class << self
    def gcs_client
      project = Gitlab::Util.get_env('OMNIBUS_GIT_CACHE_PROJECT')
      service_account_file = Gitlab::Util.get_env('OMNIBUS_GIT_CACHE_SA')
      Google::Cloud::Storage.new(project: project, credentials: service_account_file)
    end

    def bucket_name
      Gitlab::Util.get_env('OMNIBUS_GIT_CACHE_BUCKET')
    end

    def remote_path
      job_name = Gitlab::Util.get_env('CI_JOB_NAME')
      suffix = Gitlab::Util.get_env('CACHE_KEY_SUFFIX')
      "git_cache/#{job_name}-#{Build::Info.edition}#{suffix}"
    end

    def local_path
      "cache/#{OhaiHelper.platform_dir}"
    end

    def upload
      bucket = gcs_client.bucket bucket_name
      bucket.create_file local_path, remote_path

      puts "Cache uploaded successfully from #{local_path} to #{remote_path}."
    end

    def download
      FileUtils.mkdir_p('cache')

      bucket = gcs_client.bucket bucket_name
      file = bucket.file remote_path
      unless file
        puts "Cache not found."
        return
      end

      file.download local_path

      puts "Cache downloaded successfully from #{remote_path} to #{local_path}."
    end
  end
end
