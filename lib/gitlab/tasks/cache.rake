require 'fileutils'
require "open3"
require_relative "../ohai_helper.rb"

namespace :cache do
  desc "Populate cache"
  task :populate do
    system(*%w[bin/omnibus cache populate])
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

  desc "Prepare cache bundle"
  task :bundle do
    platform_dir = OhaiHelper.platform_dir

    # Prune all the gitlab-rails software tags
    Open3.pipeline(
      %w[git --git-dir=/var/cache/omnibus/cache/git_cache/opt/gitlab tag -l -n gitlab-rails-*],
      ["awk '{print $1}'"],
      %w[xargs -l git --git-dir=/var/cache/omnibus/cache/git_cache/opt/gitlab tag --delete]
    )
    system(*%w[git --git-dir=/var/cache/omnibus/cache/git_cache/opt/gitlab reflog expire --expire=now --all])
    system(*%w[git --git-dir=/var/cache/omnibus/cache/git_cache/opt/gitlab gc --prune=now --aggressive])

    system(*%W[git --git-dir=/var/cache/omnibus/cache/git_cache/opt/gitlab bundle create cache/#{platform_dir} --tags])
  end

  desc "Restore cache bundle"
  task :restore do
    platform_dir = OhaiHelper.platform_dir
    system(*%W[git clone --mirror cache/#{platform_dir} /var/cache/omnibus/cache/git_cache/opt/gitlab]) if File.exist?("cache/#{platform_dir}") && File.file?("cache/#{platform_dir}")
  end
end
