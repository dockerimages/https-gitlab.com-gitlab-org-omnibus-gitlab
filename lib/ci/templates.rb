# frozen_string_literal: true

module Ci
  class Templates
    class << self
      def global_contents
        global_variables.merge(global_before_script)
      end

      def global_variables
        { variables: {} }
      end

      def global_before_script
        {
          before_script: [
            'mkdir -p ~/.ssh',
            'mkdir -p ~/.aws',
            'mkdir -p cache',
            'if [ -n "$DEV_GITLAB_SSH_KEY" ]; then echo "$DEV_GITLAB_SSH_KEY" > ~/.ssh/id_rsa; cp support/known_hosts ~/.ssh/known_hosts; chmod -R 0600 ~/.ssh/; fi',
            'bundle config set --local path "gems"',
            'bundle config set --local without "rubocop"',
            'if [ "$INCLUDE_PACKAGECLOUD" = "true" ]; then bundle config set --local with "packagecloud"; fi',
            'echo -e "section_start:`date +%s`:bundle_install[collapsed=true]\r\e[0Kbundle install -j $(nproc)"',
            'bundle install -j $(nproc)',
            'echo -e "section_end:`date +%s`:bundle_install\r\e[0K"',
            'bundle binstubs --all',
            # If ALTERNATIVE_SOURCES are used, the public mirror for omnibus will be used.
            # This will alter Gemfile.lock file. As part of the build pipeline, we are
            # checking whether the state of the repository is unchanged during the build
            # process, by comparing it with the last commit (So that no unexpected monsters
            # show up). So, an altered Gemfile.lock file will fail on this
            # check. Hence we do a git commit as part of the pipeline if
            # ALTERNATIVE_SOURCES is used.
            'if [ -n "$ALTERNATIVE_SOURCES" ]; then git config --global user.email "packages@gitlab.com"; git config --global user.name "GitLab Inc."; git add Gemfile.lock || true ; git commit -m "Updating Gemfile.lock" || true; fi'
          ]
        }
      end

      def install_gems
        [
          "bundle config set --local path 'gems'",
          "bundle install -j $(nproc)",
          "bundle binstubs --all"
        ]
      end

      def gems_cache
        {
          key: "gems-cache-${BUILDER_IMAGE_REVISION}",
          paths: [
            'gems'
          ],
          policy: 'pull'
        }
      end

      def trigger_package_cache
        {
          key: "Ubuntu-20.04-branch-${BUILDER_IMAGE_REVISION}-v1",
          paths: [
            'cache',
            'gems',
            'assets_cache',
            'node_modules',
          ],
          policy: 'pull'
        }
      end

      def build_package_script
        [
          'bundle exec rake cache:populate',
          'bundle exec rake cache:restore',
          'bundle exec rake build:project',
          'bundle exec rake cache:bundle',
        ]
      end

      def knapsack_artifacts
        {
          expire_in: '31d',
          paths: [
            'knapsack/'
          ]
        }
      end

      def docker_job
        {
          image: "${BUILDER_IMAGE_REGISTRY}/ruby_docker:${BUILDER_IMAGE_REVISION}",
          variables: {
            DOCKER_DRIVER: 'overlay2',
            DOCKER_HOST: 'tcp://docker:2375'
          },
          services: ['docker:20.10.2-dind'],
          tags: ['gitlab-org-docker']
        }
      end
    end
  end
end
