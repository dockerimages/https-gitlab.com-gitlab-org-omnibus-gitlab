# frozen_string_literal: true

require_relative 'jobs'

module Ci
  TEST_STAGES = {
    stages: %w[
      check
      prepare
      test
      post-test
      package-and-qa
    ]
  }.freeze

  PACKAGE_AND_QA_STAGES = {
    stages: %w[
      prepare
      package
      image
      qa
    ]
  }.freeze

  OPERATING_SYSTEMS = {
    "CentOS-7" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-centos7',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/centos_7:${BUILDER_IMAGE_REVISION}"'
    },
    "CentOS-8" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-centos8',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/centos_8:${BUILDER_IMAGE_REVISION}"'
    },
    "CentOS-8-arm" => {
      tests: false,
      ce_builds: true,
      ee_builds: true,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/centos_8_arm64:${BUILDER_IMAGE_REVISION}"'
    },
    "Debian-9" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-stretch',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/debian_9:${BUILDER_IMAGE_REVISION}"'
    },
    "Debian-10" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-buster',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/debian_10:${BUILDER_IMAGE_REVISION}"'
    },
    "Debian-10-arm" => {
      tests: false,
      ce_builds: true,
      ee_builds: true,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/debian_10_arm64:${BUILDER_IMAGE_REVISION}"'
    },
    "openSUSE-15.1" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-opensuse15.1',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/opensuse_15.1:${BUILDER_IMAGE_REVISION}"'
    },
    "openSUSE-15.1-arm" => {
      tests: false,
      ce_builds: true,
      ee_builds: true,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/opensuse_15.1_arm64:${BUILDER_IMAGE_REVISION}"'
    },
    "openSUSE-15.2" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-opensuse15.2',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/opensuse_15.2:${BUILDER_IMAGE_REVISION}"'
    },
    "openSUSE-15.2-arm" => {
      tests: false,
      ce_builds: true,
      ee_builds: true,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/opensuse_15.2_arm64:${BUILDER_IMAGE_REVISION}"'
    },
    "Ubuntu-16.04" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-xenial',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/ubuntu_16.04:${BUILDER_IMAGE_REVISION}"'
    },
    "Ubuntu-18.04" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-bionic',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/ubuntu_18.04:${BUILDER_IMAGE_REVISION}"'
    },
    "Ubuntu-20.04" => {
      tests: true,
      ce_builds: true,
      ee_builds: true,
      test_image: 'registry.gitlab.com/gitlab-org/gitlab-build-images:omnibus-gitlab-focal',
      build_image: '"${BUILDER_IMAGE_REGISTRY}/ubuntu_20.04:${BUILDER_IMAGE_REVISION}"'
    },
    "Ubuntu-20.04-arm" => {
      tests: false,
      ce_builds: true,
      ee_builds: true,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/ubuntu_20.04_arm:${BUILDER_IMAGE_REVISION}"'
    },
    "Raspberry-Pi-2-Buster" => {
      tests: false,
      ce_builds: true,
      ee_builds: false,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/rpi_10:${BUILDER_IMAGE_REVISION}"'
    },
    "SLES-12.2" => {
      tests: false,
      ce_builds: false,
      ee_builds: true,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/sles_12sp2:${BUILDER_IMAGE_REVISION}"'
    },
    "SLES-12.5" => {
      tests: false,
      ce_builds: false,
      ee_builds: true,
      build_image: '"${BUILDER_IMAGE_REGISTRY}/sles_12sp5:${BUILDER_IMAGE_REVISION}"'
    }
  }.freeze

  PIPELINES = {
    'feature-branch' => [
      Ci::TEST_STAGES,
      Ci::Jobs.check_jobs,
      Ci::Jobs.prepare_jobs,
      Ci::Jobs.test_jobs,
      Ci::Jobs.post_test_jobs,
      Ci::Jobs.trigger_jobs
    ],
    'ce-triggered' => [
      Ci::PACKAGE_AND_QA_STAGES,
      Ci::Jobs.package_and_qa_jobs,
    ],
    'ee-triggered' => [
      Ci::PACKAGE_AND_QA_STAGES,
      Ci::Jobs.package_and_qa_jobs(ee: true),
    ],
    'ce-branch-build' => [],
    'ee-branch-build' => [],
    'ce-nightly-build' => [],
    'ee-nightly-build' => [],
    'ce-regular-tag-build' => [],
    'ee-regular-tag-build' => [],
    'ce-rc-tag-build' => [],
    'ee-rc-tag-build' => [],
    'auto-deploy-tag-build' => [],
    'cache-update' => [],
    'update-license-pages' => [],
    'dependencies-io-check' => [],
    'dependencies-io-update' => []
  }.freeze
end
