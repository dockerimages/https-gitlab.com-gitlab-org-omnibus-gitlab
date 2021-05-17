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

      def omnibus_gitlab_mirror_trigger_variables
        job = {
          ALTERNATIVE_SOURCES: "true",
          BUILDER_IMAGE_REVISION: Gitlab::Util.get_env('BUILDER_IMAGE_REVISION').to_s,
          BUILDER_IMAGE_REGISTRY: Gitlab::Util.get_env('BUILDER_IMAGE_REGISTRY').to_s,
          PUBLIC_BUILDER_IMAGE_REGISTRY: Gitlab::Util.get_env('PUBLIC_BUILDER_IMAGE_REGISTRY').to_s,
          COMPILE_ASSETS: Gitlab::Util.get_env('COMPILE_ASSETS').to_s,
          ee: Gitlab::Util.get_env('ee').to_s,
          TRIGGERED_USER: Gitlab::Util.get_env('TRIGGERED_USER').to_s,
          TRIGGER_SOURCE: Gitlab::Util.get_env('TRIGGER_SOURCE').to_s,
          TOP_UPSTREAM_SOURCE_PROJECT: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT').to_s,
          TOP_UPSTREAM_SOURCE_JOB: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_JOB').to_s,
          TOP_UPSTREAM_SOURCE_SHA: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_SHA').to_s,
          TOP_UPSTREAM_SOURCE_REF: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_REF').to_s,
          GITLAB_VERSION: Gitlab::Util.get_env('GITLAB_VERSION').to_s,
          GITLAB_SHELL_VERSION: Gitlab::Util.get_env('GITLAB_SHELL_VERSION').to_s,
          GITLAB_PAGES_VERSION: Gitlab::Util.get_env('GITLAB_PAGES_VERSION').to_s,
          GITALY_SERVER_VERSION: Gitlab::Util.get_env('GITALY_SERVER_VERSION').to_s,
          GITLAB_ELASTICSEARCH_INDEXER_VERSION: Gitlab::Util.get_env('GITLAB_ELASTICSEARCH_INDEXER_VERSION').to_s,
          GITLAB_KAS_VERSION: Gitlab::Util.get_env('GITLAB_KAS_VERSION').to_s,
        }

        job[:QA_BRANCH] = Gitlab::Util.get_env('QA_BRANCH') if Gitlab::Util.get_env('QA_BRANCH')

        job
      end

      def gitlab_qa_mirror_trigger_variables
        {
          RELEASE: Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag),
          QA_IMAGE: Gitlab::Util.get_env('QA_IMAGE').to_s,
          TRIGGERED_USER: Gitlab::Util.get_env("TRIGGERED_USER").to_s || Gitlab::Util.get_env("GITLAB_USER_NAME").to_s,
          TRIGGER_SOURCE: Gitlab::Util.get_env('CI_JOB_URL').to_s,
          TOP_UPSTREAM_SOURCE_PROJECT: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_PROJECT').to_s,
          TOP_UPSTREAM_SOURCE_JOB: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_JOB').to_s,
          TOP_UPSTREAM_SOURCE_SHA: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_SHA').to_s,
          TOP_UPSTREAM_SOURCE_REF: Gitlab::Util.get_env('TOP_UPSTREAM_SOURCE_REF').to_s,
          TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID: Gitlab::Util.get_env('TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID').to_s,
          TOP_UPSTREAM_MERGE_REQUEST_IID: Gitlab::Util.get_env('TOP_UPSTREAM_MERGE_REQUEST_IID').to_s
        }
      end
    end
  end
end
