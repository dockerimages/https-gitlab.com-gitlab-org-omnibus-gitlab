require_relative 'object_proxy'
require_relative 'helpers/logging_helper'

module Gitlab
  class Deprecations
    class << self
      ATTRIBUTE_BLOCKS ||= %w[gitlab monitoring].freeze

      def list(existing_config = nil)
        # List of deprecations. Remember to convert underscores to hyphens for
        # the first level configurations (eg: gitlab_rails => gitlab-rails)
        # Use the following structure:
        # {
        #   config_keys: %w(<space separated list>),
        #   deprecation: '<version when deprecated>',
        #   removal: '<version when to be removed>' # <link to removal issue>
        #   note: '<Any extra notes>'
        # }
        #
        # `config_keys` represents a list of keys, which can be used to traverse
        # the configuration hash available from /opt/gitlab/embedded/nodes/{fqdn}json
        # to reach a specific configuration. For example %w(mattermost
        # log_file_directory) means `mattermost['log_file_directory']` setting.
        # Similarly, %w(gitlab nginx listen_addresses) means
        # `gitlab['nginx']['listen_addresses']`. We internally convert it to
        # nginx['listen_addresses'], which is what we use in /etc/gitlab/gitlab.rb
        #
        # If you need to deprecate configuration relating to a component entirely,
        # make use of the `identify_deprecated_config` method. You can do this
        # by adding a line like the following before the return statement of
        # this method.
        # deprecations += identify_deprecated_config(existing_config, ['gitlab', 'foobar'], {}, "13.12", "14.0", "Support for foobar will be removed in GitLab 14.0")
        deprecations = [
          {
            config_keys: %w(gitaly cgroups_count),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_repositories_count']` instead."
          },
          {
            config_keys: %w(gitaly cgroups_memory_enabled),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_memory_bytes'] or gitaly['cgroups_repositories_memory_bytes'] instead."
          },
          {
            config_keys: %w(gitaly cgroups_memory_limit),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_memory_bytes'] or gitaly['cgroups_repositories_memory_bytes'] instead."
          },
          {
            config_keys: %w(gitaly cgroups_cpu_enabled),
            deprecation: '15.1',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6828
            note: "Use `gitaly['cgroups_cpu_shares'] or gitaly['cgroups_repositories_cpu_shares'] instead."
          },
          {
            config_keys: %w(gitaly ruby_rugged_git_config_search_path),
            deprecation: '15.1',
            removal: '15.1',
            note: "Starting with GitLab 15.1, Rugged does not read the Git configuration anymore. Instead, Gitaly knows to configure Rugged as required."
          },
          {
            config_keys: %w(praefect separate_database_metrics),
            deprecation: '15.5',
            removal: '16.0', # https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7072
            note: "Starting with GitLab 16.0, Praefect DB metrics will no longer be available on `/metrics` and must be scraped from `/db_metrics`."
          },
          {
            config_keys: %w(gitlab gitlab-rails enable_jemalloc),
            deprecation: '15.5',
            removal: '15.5',
            note: "Starting with GitLab 15.5, jemalloc is compiled in with the Ruby interpreter and can no longer be disabled."
          },
          {
            config_keys: %w(gitlab gitlab-rails gitlab_default_can_create_group),
            deprecation: '15.5',
            removal: '16.0',
            note: "Starting with GitLab 15.5, this setting cannot be controlled via the configuration file anymore. Follow the steps at https://docs.gitlab.com/ee/user/admin_area/settings/account_and_limit_settings.html#prevent-users-from-creating-top-level-groups, to configure this setting via the Admin UI or the API"
          }
        ]

        deprecations += identify_deprecated_config(existing_config, ['gitlab', 'unicorn'], ['enable', 'svlogd_prefix'], "13.10", "14.0", "Starting with GitLab 14.0, Unicorn is no longer supported and users must switch to Puma, following https://docs.gitlab.com/ee/administration/operations/puma.html.")
        deprecations += identify_deprecated_config(existing_config, ['repmgr'], ['enable'], "13.3", "14.0", "Starting with GitLab 14.0, Repmgr is no longer supported and users must switch to Patroni, following https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#switching-from-repmgr-to-patroni.")
        deprecations += identify_deprecated_config(existing_config, ['repmgrd'], ['enable'], "13.3", "14.0", "Starting with GitLab 14.0, Repmgr is no longer supported and users must switch to Patroni, following https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#switching-from-repmgr-to-patroni.")

        deprecations
      end

      def identify_deprecated_config(existing_config, config_keys, allowed_keys, deprecation, removal, note = nil)
        # Method to simplify deprecating a bulk of configuration related to a
        # component. In short, it generates and returns a list of deprecated
        # configuration from the complete list using a smaller list of
        # supported keys. The output is formatted as a list of hashes, similar
        # to the one from `GitLab::Deprecations.list` above.
        # The parameters are
        # 1. existing_config: The high level configuration from fqdn.json file
        # 2. config_keys: The keys that make up the hash which contains
        #                 configuration to be deprecated. Check comment inside
        #                 `list` method above for more details.
        # 3. allowed_keys: List of allowed keys
        # 4. deprecation: Version since which were the configurations deprecated
        # 5. removal: Version in which were the configurations removed
        # 6. note: General note regarding removal
        return [] unless existing_config

        matching_config = existing_config.dig(*config_keys)
        return [] unless matching_config

        deprecated_config = matching_config.reject { |config| allowed_keys.include?(config) }
        deprecated_config.keys.map do |key|
          {
            config_keys: config_keys + [key],
            deprecation: deprecation,
            removal: removal,
            note: note
          }
        end
      end

      def next_major_version
        version_manifest = JSON.parse(File.read("/opt/gitlab/version-manifest.json"))
        major_version = version_manifest['build_version'].split(".")[0]
        (major_version.to_i + 1).to_s
      rescue StandardError
        puts "Error reading /opt/gitlab/version-manifest.json. Please check if the file exists and JSON content in it is not malformed."
        puts "Checking for deprecated configuration failed."
      end

      def applicable_deprecations(incoming_version, existing_config, type)
        # Return the list of deprecations or removals that are applicable with
        # a given list of configuration for a specific version.
        incoming_version = next_major_version if incoming_version.empty?
        return [] unless incoming_version

        version = Gem::Version.new(incoming_version)

        # Getting settings from gitlab.rb that are in deprecations list and
        # has been removed in incoming or a previous version.
        current_deprecations = list(existing_config).select { |deprecation| version >= Gem::Version.new(deprecation[type]) }
        current_deprecations.select { |deprecation| !existing_config.dig(*deprecation[:config_keys]).nil? }
      end

      def check_config(incoming_version, existing_config, type = :removal)
        messages = []
        deprecated_config = applicable_deprecations(incoming_version, existing_config, type)
        deprecated_config.each do |deprecation|
          config_keys = deprecation[:config_keys].dup
          config_keys.shift if ATTRIBUTE_BLOCKS.include?(config_keys[0])
          key = if config_keys.length == 1
                  config_keys[0].tr("-", "_")
                elsif config_keys.first.eql?('roles')
                  "#{config_keys[1].tr('-', '_')}_role"
                else
                  "#{config_keys[0].tr('-', '_')}['#{config_keys.drop(1).join("']['")}']"
                end

          if type == :deprecation
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and will be removed in #{deprecation[:removal]}."
          elsif type == :removal
            message = "* #{key} has been deprecated since #{deprecation[:deprecation]} and was removed in #{deprecation[:removal]}."
          end
          message += " " + deprecation[:note] if deprecation[:note]
          messages << message
        end

        messages += additional_deprecations(incoming_version, existing_config, type)

        messages
      end

      def additional_deprecations(incoming_version, existing_config, type)
        messages = []
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['gitlab', 'unicorn'], 'enable', true, '13.10', '14.0')
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['repmgr'], 'enable', true, '13.3', '14.0')
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['repmgrd'], 'enable', true, '13.3', '14.0')

        praefect_note = <<~EOS
          From GitLab 14.0 onwards, the `per_repository` will be the only available election strategy.
          Migrate to repository-specific primary nodes following
          https://docs.gitlab.com/ee/administration/gitaly/praefect.html#migrate-to-repository-specific-primary-gitaly-nodes.
        EOS
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['praefect'], 'failover_election_strategy', 'sql', '13.12', '14.0', note: praefect_note, ignore_deprecation: true)
        messages += deprecate_only_if_value(incoming_version, existing_config, type, ['praefect'], 'failover_election_strategy', 'local', '13.12', '14.0', note: praefect_note, ignore_deprecation: true)

        messages
      end

      def deprecate_only_if_value(incoming_version, existing_config, type, config_keys, key, value, deprecated_version, removed_version, note: nil, ignore_deprecation: false) # rubocop:disable Metrics/ParameterLists
        setting = existing_config.dig(*config_keys) || {}

        return [] unless setting.key?(key)

        # Return empty array if the setting is either nil or an empty collection (Array, Hash, etc.).
        # `to_h` will convert `nil` to an empty array.
        return [] if setting[key].respond_to?(:to_h) && setting[key].to_h.empty?

        # Do not add messages for removals. We only handle deprecations here.
        return [] if type == :removal && setting[key] != value

        config_keys.shift if ATTRIBUTE_BLOCKS.include?(config_keys[0])
        messages = []

        if Gem::Version.new(incoming_version) >= Gem::Version.new(removed_version) && type == :removal
          message = "* #{config_keys[0]}[#{key}] has been deprecated since #{deprecated_version} and was removed in #{removed_version}."
          message += " #{note}" if note
          messages << message
        elsif Gem::Version.new(incoming_version) >= Gem::Version.new(deprecated_version) && type == :deprecation && !ignore_deprecation
          message =  "* #{config_keys[0]}[#{key}] has been deprecated since #{deprecated_version} and will be removed in #{removed_version}."
          message += " #{note}" if note
          messages << message
        end

        messages
      end
    end

    class NodeAttribute < ObjectProxy
      def self.log_deprecations?
        @log_deprecations || false
      end

      def self.log_deprecations=(value = true)
        @log_deprecations = !!value
      end

      def initialize(target, var_name, new_var_name)
        @target = target
        @var_name = var_name
        @new_var_name = new_var_name
      end

      def method_missing(method_name, *args, &block) # rubocop:disable Style/MissingRespondToMissing
        deprecated_msg(caller[0..2]) if NodeAttribute.log_deprecations?
        super
      end

      private

      def deprecated_msg(*called_from)
        called_from = called_from.flatten
        msg = "Accessing #{@var_name} is deprecated. Support will be removed in a future release. \n" \
              "Please update your cookbooks to use #{@new_var_name} in place of #{@var_name}. Accessed from: \n"
        called_from.each { |l| msg << "#{l}\n" }
        LoggingHelper.deprecation(msg)
      end
    end
  end
end
