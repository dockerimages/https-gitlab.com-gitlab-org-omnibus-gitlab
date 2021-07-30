require 'fileutils'
require_relative "../ohai_helper.rb"
require_relative "../cache_helper"

namespace :cache do
  desc "Populate cache"
  task :populate do
    Gitlab::Util.section('cache:populate') do
      system(*%w[bin/omnibus cache populate])
    end
  end

  desc "Purge existing cache"
  task :purge do
    [
      # Force a new clone of gitlab-rails because we change remotes for CE/EE
      "/var/cache/omnibus/src/gitlab-rails",

      # Avoid mysterious GitFetcher omnibus errors
      "/var/cache/omnibus/src/gitlab-shell",
      "/var/cache/omnibus/src/gitlab-workhorse",

      # Clear out old packages to prevent uploading them a second time to S3
      "/var/cache/omnibus/pkg"
    ].each do |path|
      FileUtils.rm_r path, force: true, secure: true
    end
    FileUtils.rm_r 'pkg', force: true, secure: true
    FileUtils.mkdir_p 'pkg'
  end

  desc "Prepare git_cache bundle"
  task :bundle do
    platform_dir = OhaiHelper.platform_dir
    system(*%W[git --git-dir=/var/cache/omnibus/cache/git_cache/opt/gitlab bundle create cache/#{platform_dir} --tags])
  end

  desc "Upload git_cache bundle"
  task :upload do
    CacheHelper.upload
  rescue StandardError => e
    # Intentionally catching every exception because we don't want any failure
    # here to cause the build to fail. The worst that can happen is a longer
    # build time.
    puts "Uploading cache failed. Details below."
    puts e.inspect
  end

  desc "Download git_cache bundle"
  task :download do
    CacheHelper.download
  rescue StandardError => e
    # Intentionally catching every exception because we don't want any failure
    # here to cause the build to fail. The worst that can happen is a longer
    # build time.
    puts "Downloading cache failed. Details below."
    puts e.inspect
  end

  desc "Restore git_cache bundle"
  task :restore do
    platform_dir = OhaiHelper.platform_dir
    system(*%W[git clone --mirror cache/#{platform_dir} /var/cache/omnibus/cache/git_cache/opt/gitlab]) if File.exist?("cache/#{platform_dir}") && File.file?("cache/#{platform_dir}")
  end
end
