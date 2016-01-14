module Gitlab
  class BuildVersion
    def initialize
      gitlab_version_file =  File.expand_path("VERSION", Omnibus::Config.project_root)
      @version = File.read(gitlab_version_file).strip
    rescue Errno::ENOENT
      # No file
    end

    def build_version
      if @version && @version.include?(".pre")
        build_pre_version
      else
        omnibus_build_version.semver
      end
    end

    private

    def build_pre_version
      version_tag = version_composition.join('.')
      version_tag << '-' << "nightly" << '+' << omnibus_build_version.build_start_time
    end

    # Borrowed from omnibus
    # https://github.com/chef/omnibus/blob/v5.0.0/lib/omnibus/build_version.rb#L273
    def version_composition
      version_regexp = /^v?(\d+)\.(\d+)\.(\d+)/

      if match = version_regexp.match(@version)
        match[1..3]
      else
        raise "Invalid semver tag `#{@version}'!"
      end
    end

    def omnibus_build_version
      Omnibus::BuildVersion.new
    end
  end
end
