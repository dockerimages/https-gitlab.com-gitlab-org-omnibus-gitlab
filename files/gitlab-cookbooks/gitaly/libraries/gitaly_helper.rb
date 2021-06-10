class GitalyHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def gitaly_version
    VersionHelper.version('/opt/gitlab/embedded/gitaly/packaged/bin/gitaly --version').split.last
  end
end
