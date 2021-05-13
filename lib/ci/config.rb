# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/hash/keys'

require_relative 'vars'
require_relative '../gitlab/util'
require_relative '../gitlab/build/check'

module Ci
  class Config
    AUTO_DEPLOY_TAG_REGEX = /^\d+\.\d+\.\d+\+[^ ]{7,}\.[^ ]{7,}$/.freeze
    RC_TAG_REGEX = /^.*\+rc.*/.freeze

    attr_reader :pipeline_type, :pipeline_jobs

    def initialize
      @project_path = Gitlab::Util.get_env('CI_PROJECT_PATH')
      @project_branch = Gitlab::Util.get_env('CI_COMMIT_BRANCH')
      @project_tag = Gitlab::Util.get_env('CI_COMMIT_TAG')
      @ee_var = Gitlab::Util.get_env('ee')
      @skip_release = Gitlab::Util.get_env('SKIP_RELEASE')

      @pipeline_type = get_pipeline_type
      @pipeline_jobs = [Ci::Templates.global_contents]
    end

    def execute
      @pipeline_jobs += Ci::PIPELINES[@pipeline_type].flatten
    end

    def print_pipeline
      puts @pipeline_jobs.inject(&:merge).deep_stringify_keys.to_yaml(indentation: 2)
    end

    def write_pipeline
      File.write('generated-ci-config.yml', @pipeline_jobs.inject(&:merge).deep_stringify_keys.to_yaml(indentation: 2))
    end

    private

    def get_pipeline_type
      case @project_path
      when 'gitlab-org/omnibus-gitlab'
        get_canonical_pipeline_type
      when 'gitlab/omnibus-gitlab'
        get_release_pipeline_type
      when 'gitlab-org/build/omnibus-gitlab-mirror'
        get_mirror_pipeline_type
      else
        puts "Seems to be run locally. Defaulting to canonical feature branch pipeline."
        'feature-branch'
      end
    end

    def get_canonical_pipeline_type
      if Gitlab::Util.get_env('CACHE_UPDATE') == 'true'
        puts 'Detected cache-update pipeline'
        'cache-update'
      elsif Gitlab::Util.get_env('DEPS_PIPELINE') == 'true'
        puts 'Detected dependencies-io-check pipeline'
        'dependencies-io-check'
      elsif Gitlab::Util.get_env('LICENSE_PAGS_UPDATE') == 'true'
        puts 'Detected update-license-pages pipeline'
        'update-license-pages'
      else
        puts 'Detected feature branch pipeline'
        'feature-branch'
      end
    end

    def get_release_pipeline_type
      if @project_tag&.match?(AUTO_DEPLOY_TAG_REGEX)
        puts 'Detected auto-deploy tag pipeline'
        'auto-deploy-tag-build'
      elsif @project_tag&.match?(RC_TAG_REGEX)
        puts 'Detected RC tag pipeline'
        "#{edition_prefix}-rc-tag-build"
      elsif @project_tag
        puts 'Detected regular tag pipeline'
        "#{edition_prefix}-regular-tag-build"
      elsif Gitlab::Util.get_env('NIGHTLY') == 'true'
        puts 'Detected nightly pipeline'
        "#{edition_prefix}-nightly-build"
      else
        puts 'Detected regular branch build pipeline'
        "#{edition_prefix}-branch-build"
      end
    end

    def get_mirror_pipeline_type
      "#{edition_prefix}-triggered"
    end

    def edition_prefix
      Build::Check.is_ee? ? 'ee' : 'ce'
    end
  end
end
