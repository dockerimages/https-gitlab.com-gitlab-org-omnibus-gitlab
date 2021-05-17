# frozen_string_literal: true

require 'active_support/core_ext/hash/deep_merge'

require_relative '../gitlab/util'
require_relative '../gitlab/build/check'
require_relative '../gitlab/build/info'
require_relative 'templates'

module Ci
  class Jobs
    class << self
      def check_jobs
        {
          'danger-review' => danger_review,
          'docs-lint-links' => docs_lint_links,
          'docs-lint-markdown' => docs_lint_markdown,
          'rubocop' => rubocop,
          'check-mirroring' => check_mirroring
        }
      end

      def prepare_jobs
        knapsack_jobs
      end

      def test_jobs
        rspec_jobs
      end

      def post_test_jobs
        {
          'update-knapsack' => update_knapsack
        }
      end

      def package_and_qa_jobs(ee: false)
        jobs = {
          'fetch-assets' => fetch_assets,
          'ubuntu-package' => build_triggered_package,
          'gitlab-docker' => build_triggerred_gitlab_image,
          'qa-docker' => build_triggerred_qa_image,
          'gitlab-qa' => run_qa_test
        }

        jobs['RAT'] = run_rat_test if ee

        jobs
      end

      def danger_review
        {
          image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:danger',
          stage: 'check',
          cache: {},
          needs: [],
          before_script: [],
          script: [
            'danger --fail-on-errors=true'
          ]
        }
      end

      def docs_lint_links
        {
          image: 'registry.gitlab.com/gitlab-org/gitlab-docs/lint-html:alpine-3.13-ruby-2.7.2',
          stage: 'check',
          cache: {},
          needs: [],
          before_script: [],
          script: [
            'mv doc/ /tmp/gitlab-docs/content/omnibus',
            'cd /tmp/gitlab-docs',
            'bundle exec nanoc',
            'bundle exec nanoc check internal_links',
            'bundle exec nanoc check internal_anchors',
          ]
        }
      end

      def docs_lint_markdown
        {
          image: 'registry.gitlab.com/gitlab-org/gitlab-docs/lint-markdown:alpine-3.13-vale-2.10.2-markdownlint-0.26.0',
          stage: 'check',
          cache: {},
          needs: [],
          before_script: [],
          script: [
            'vale --minAlertLevel error doc',
            "markdownlint --config .markdownlint.json 'doc/**/*.md'"
          ]
        }
      end

      def rubocop
        {
          image: "${RUBY_IMAGE}",
          stage: 'check',
          needs: [],
          before_script: Ci::Templates.install_gems,
          script: [
            'bundle exec rubocop --parallel'
          ],
          cache: Ci::Templates.gems_cache,
        }
      end

      def check_mirroring
        {
          stage: 'check',
          cache: Ci::Templates.gems_cache,
          image: "alpine:latest",
          before_script: [
            'apk --no-cache add curl bash'
          ],
          script: [
            'bash support/wait_for_sha',
          ],
          needs: [],
        }
      end

      def knapsack_jobs
        jobs = {}
        body = {
          stage: 'prepare',
          before_script: [],
          script: [
            'JOB_NAME=( ${CI_JOB_NAME//-/ } )',
            "export DISTRO_NAME=${JOB_NAME[0]}",
            "export DISTRO_VERSION=${JOB_NAME[1]}",
            "mkdir -p knapsack/",
            '[[ -f knapsack/${DISTRO_NAME}_${DISTRO_VERSION}_main_rspec_report.json ]] || echo "{}" > knapsack/${DISTRO_NAME}_${DISTRO_VERSION}_main_rspec_report.json'
          ],
          cache: {
            key: "knapsack",
            paths: [
              'knapsack/'
            ]
          },
          artifacts: Ci::Templates.knapsack_artifacts,
          needs: ['rubocop'],
          retry: 1,
        }

        Ci::OPERATING_SYSTEMS.select { |name, details| details[:tests] == true }.each do |os, details|
          jobs["#{os}-knapsack"] = body
        end

        jobs
      end

      def rspec_jobs
        jobs = {}
        body = {
          stage: 'test',
          parallel: 6,
          before_script: [
            'export ALTERNATIVE_SOURCES=true',
            Ci::Templates.install_gems,
          ].flatten,
          cache: Ci::Templates.gems_cache,
          script: [
            'JOB_NAME=( ${CI_JOB_NAME//-/ } )',
            'export DISTRO_NAME=${JOB_NAME[0]}',
            'export DISTRO_VERSION=${JOB_NAME[1]}',
            'export KNAPSACK_REPORT_PATH=knapsack/${DISTRO_NAME}_${DISTRO_VERSION}_rspec_node_${CI_NODE_INDEX}_${CI_NODE_TOTAL}_report.json',
            'export KNAPSACK_GENERATE_REPORT=true',
            'export USE_KNAPSACK=true',
            # To prevent current OS providing empty/old reports of other OSs as an
            # artifact. If not, they may overwrite the valid/new reports from those
            # corresponding OSs. So, removing everything except current OS's report.
            'cp knapsack/${DISTRO_NAME}_${DISTRO_VERSION}_main_rspec_report.json ${KNAPSACK_REPORT_PATH}.bak',
            'rm -f knapsack/*.json',
            'mv ${KNAPSACK_REPORT_PATH}.bak ${KNAPSACK_REPORT_PATH}',
            'bundle exec rake "knapsack:rspec[--color --format RspecJunitFormatter --out junit_rspec.xml --format documentation]"'
          ],
          artifacts: Ci::Templates.knapsack_artifacts.merge(
            reports: {
              junit: 'junit_rspec.xml'
            }
          ),
          retry: 1
        }

        Ci::OPERATING_SYSTEMS.select { |name, details| details[:tests] == true }.each do |os, details|
          jobs["#{os}-specs"] = body.merge(
            image: details[:test_image],
            needs: ["#{os}-knapsack"]
          )
        end

        jobs
      end

      def update_knapsack
        {
          image: "${RUBY_IMAGE}",
          stage: 'post-test',
          before_script: [],
          script: [
            'support/merge-reports knapsack',
            'rm -f knapsack/*node*'
          ],
          cache: {
            key: "knapsack",
            paths: [
              'knapsack/'
            ]
          },
          artifacts: Ci::Templates.knapsack_artifacts,
          retry: 1
        }
      end

      def trigger_jobs
        jobs = {}
        body = {
          stage: 'package-and-qa',
          when: 'manual',
          trigger: {
            project: Build::Info::OMNIBUS_PROJECT_MIRROR_PATH,
            branch: "${CI_COMMIT_REF_NAME}",
            strategy: 'depend'
          },
          variables: Ci::Templates.omnibus_gitlab_mirror_trigger_variables,
          needs: ['check-mirroring'],
        }

        jobs["Trigger:ce-package-and-qa"] = body
        jobs["Trigger:ee-package-and-qa"] = body.deep_merge(variables: { ee: "true" })

        jobs
      end

      def fetch_assets
        job = Ci::Templates.docker_job
        job.merge!(
          stage: 'prepare',
          timeout: '1h',
          before_script: [],
          script: [
            'export VERSION=${GITLAB_REF_SLUG-$(ruby -I. -e \'require "lib/gitlab/version"; puts Gitlab::Version.new("gitlab-rails").print\')}',
            'support/fetch_assets "${VERSION}"'
          ],
          artifacts: {
            paths: ["assets-${CI_COMMIT_REF_SLUG}"]
          }
        )

        job
      end

      def build_triggered_package
        {
          image: "${BUILDER_IMAGE_REGISTRY}/ubuntu_20.04:${BUILDER_IMAGE_REVISION}",
          stage: 'package',
          script: [
            'if [ -n "$TRIGGERED_USER" ] && [ -n "$TRIGGER_SOURCE" ]; then echo "Pipeline triggered by $TRIGGERED_USER at $TRIGGER_SOURCE"; fi',
            Ci::Templates.build_package_script,
            'mv pkg/ubuntu-focal/*.deb pkg/ubuntu-focal/gitlab.deb',
            'bundle exec rspec --color --format RspecJunitFormatter --out junit_ci_rspec.xml --format documentation ci_build_specs',
            'bundle exec rake build:component_shas'
          ],
          needs: ['fetch-assets'],
          cache: Ci::Templates.trigger_package_cache,
          artifacts: {
            expire_in: '3 days',
            when: 'always',
            paths: ['pkg/'],
            reports: {
              junit: 'junit_ci_rspec.xml'
            }
          },
          tags: ['triggered-packages'],
        }
      end

      def build_triggerred_gitlab_image
        job = Ci::Templates.docker_job
        job.merge!(
          stage: 'image',
          script: [
            'if [ -n "$TRIGGERED_USER" ] && [ -n "$TRIGGER_SOURCE" ]; then echo "Pipeline triggered by $TRIGGERED_USER at $TRIGGER_SOURCE"; fi',
            'bundle exec rake docker:build:image',
            'bundle exec rake docker:push:triggered'
          ],
          needs: ['ubuntu-package'],
          cache: Ci::Templates.gems_cache
        )

        job
      end

      def build_triggerred_qa_image
        job = Ci::Templates.docker_job
        job.merge!(
          stage: 'image',
          script: [
            'if [ -n "$TRIGGERED_USER" ] && [ -n "$TRIGGER_SOURCE" ]; then echo "Pipeline triggered by $TRIGGERED_USER at $TRIGGER_SOURCE"; fi',
            'bundle exec rake qa:build',
            'bundle exec rake qa:push:triggered'
          ],
          needs: ['ubuntu-package'],
          cache: Ci::Templates.gems_cache
        )

        job
      end

      def run_qa_test
        {
          stage: 'qa',
          trigger: {
            project: Build::Info::QA_PROJECT_MIRROR_PATH,
            branch: Gitlab::Util.get_env('QA_BRANCH') || 'master',
            strategy: 'depend',
          },
          variables: Ci::Templates.gitlab_qa_mirror_trigger_variables,
          needs: [
            {
              job: 'ubuntu-package',
              artifacts: false
            },
            {
              job: 'gitlab-docker',
              artifacts: false
            },
            {
              job: 'qa-docker',
              artifacts: false
            }
          ]
        }
      end

      def run_rat_test
        {
          stage: 'qa',
          image: "${PUBLIC_BUILDER_IMAGE_REGISTRY}/ruby_docker:${BUILDER_IMAGE_REVISION}",
          when: 'manual',
          script: [
            'if [ -n "$TRIGGERED_USER" ] && [ -n "$TRIGGER_SOURCE" ]; then echo "Pipeline triggered by $TRIGGERED_USER at $TRIGGER_SOURCE"; fi',
            'bundle exec rake qa:rat:trigger',
          ],
          needs: [
            {
              job: 'ubuntu-package',
              artifacts: false
            },
            {
              job: 'qa-docker',
              artifacts: false
            }
          ]
        }
      end
    end
  end
end
