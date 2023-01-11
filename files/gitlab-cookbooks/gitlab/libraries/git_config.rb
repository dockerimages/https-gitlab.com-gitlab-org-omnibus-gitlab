require_relative '../../../../lib/gitlab/gitconfig_helper.rb'

module GitConfig
  class << self
    def parse_variables
      parse_git_config
    end

    def parse_git_config
      Gitlab['system_gitconfig'] ||= Gitconfig::Util.convert_gitconfig(Gitlab['omnibus_gitconfig']['system'])
    end
  end
end
