class GitalyHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def gitaly_version
    VersionHelper.version('/opt/gitlab/embedded/gitaly/packaged/bin/gitaly --version').split.last
  end

  def linked_gitaly_version
    VersionHelper.version('/opt/gitlab/embedded/bin/gitaly --version').split.last
  rescue StandardError
  end
end
