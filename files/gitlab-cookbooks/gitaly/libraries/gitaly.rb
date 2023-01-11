#
# Copyright:: Copyright (c) 2017 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/mash'
require_relative '../../package/libraries/helpers/output_helper.rb'
require_relative '../../../../lib/gitlab/gitconfig_helper.rb'

module Gitaly
  class << self
    include OutputHelper

    def parse_variables
      parse_git_data_dirs
      parse_gitaly_storages
      parse_gitconfig
    end

    def gitaly_address
      socket_path     = user_config['socket_path']     || package_default['socket_path']
      listen_addr     = user_config['listen_addr']     || package_default['listen_addr']
      tls_listen_addr = user_config['tls_listen_addr'] || package_default['tls_listen_addr']

      # Default to using socket path if available
      if tls_listen_addr && !tls_listen_addr.empty?
        "tls://#{tls_listen_addr}"
      elsif socket_path && !socket_path.empty?
        "unix:#{socket_path}"
      elsif listen_addr && !listen_addr.empty?
        "tcp://#{listen_addr}"
      end
    end

    def parse_git_data_dirs
      Gitlab['git_data_dirs'] = { "default" => { "path" => "/var/opt/gitlab/git-data" } } if Gitlab['git_data_dirs'].empty?

      Gitlab['git_data_dirs'].map do |name, details|
        Gitlab['git_data_dirs'][name]['path'] = details[:path] || details['path'] || '/var/opt/gitlab/git-data'
      end

      Gitlab['gitlab_rails']['repositories_storages'] =
        Hash[Mash.new(Gitlab['git_data_dirs']).map do |name, data_directory|
          shard_gitaly_address = data_directory['gitaly_address'] || gitaly_address

          defaults = { 'path' => File.join(data_directory['path'], 'repositories'), 'gitaly_address' => shard_gitaly_address }
          params = data_directory.merge(defaults)

          [name, params]
        end]
    end

    def parse_gitaly_storages
      return unless Gitlab['gitaly']['storage'].nil?

      storages = []
      Gitlab['gitlab_rails']['repositories_storages'].each do |key, value|
        storages << {
          'name' => key,
          'path' => value['path']
        }
      end
      Gitlab['gitaly']['storage'] = storages
    end

    # Compute the default gitconfig from the old Omnibus gitconfig setting.
    # This depends on the Gitlab cookbook having been parsed already.
    def parse_gitconfig
      # If the administrator has set `gitaly['gitconfig']` then we do not add a
      # fallback gitconfig.
      return unless Gitlab['gitaly']['gitconfig'].nil?

      # Furthermore, if the administrator has not overridden the
      # `omnibus_gitconfig` we do not have to migrate anything either. Most
      # importantly, we are _not_ interested in migrating defaults.
      return if Gitlab['omnibus_gitconfig']['system'].nil?

      # We use the old system-level Omnibus gitconfig as the default value...
      gitconfig = Gitconfig::Util.convert_gitconfig(Gitlab['omnibus_gitconfig']['system'])

      # ... but remove any of its values that had been part of the default
      # configuration when introducing the Gitaly gitconfig. We do not want to
      # inject our old default values into Gitaly anymore given that it is
      # setting its own defaults nowadays. Furthermore, we must not inject the
      # `core.fsyncObjectFiles` config entry, which has been deprecated in Git.
      gitconfig -= [
        { section: 'pack', key: 'threads', value: '1' },
        { section: 'receive', key: 'advertisePushOptions', value: 'true' },
        { section: 'receive', key: 'fsckObjects', value: 'true' },
        { section: 'repack', key: 'writeBitmaps', value: 'true' },
        { section: 'transfer', key: 'hideRefs', value: '^refs/tmp/' },
        { section: 'transfer', key: 'hideRefs', value: '^refs/keep-around/' },
        { section: 'transfer', key: 'hideRefs', value: '^refs/remotes/' },
        { section: 'core', key: 'alternateRefsCommand', value: '"exit 0 #"' },
        { section: 'core', key: 'fsyncObjectFiles', value: 'true' },
        { section: 'fetch', key: 'writeCommitGraph', value: 'true' }
      ]

      return unless gitconfig.any?

      Gitlab['gitaly']['gitconfig'] = gitconfig
    end

    private

    def user_config
      Gitlab['gitaly']
    end

    def package_default
      Gitlab['node']['gitaly'].to_hash
    end
  end
end
