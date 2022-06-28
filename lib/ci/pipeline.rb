require 'active_support/core_ext/hash'

require_relative 'jobs'
require_relative '../gitlab/util'
require_relative '../gitlab/build/check'

require 'yaml'

module CI
  class Pipeline
    VALID_PIPELINE_TYPES = [
      # Pipelines in canonical repo
      :canonical_deps_pipeline_by_schedule,
      :canonical_cache_update_pipeline_by_schedule,
      :canonical_dependency_scanning_pipeline_by_schedule,
      :canonical_deps_branch_pipeline,
      :canonical_docs_pipeline,
      :canonical_ce_branch_pipeline,
      :canonical_ce_branch_pipeline_by_schedule,
      :canonical_ee_branch_pipeline,
      :canonical_ee_branch_pipeline_by_schedule,
      :canonical_ce_tag_pipeline,
      :canonical_ee_tag_pipeline,
      # Pipelines in dev repo
      :dev_ce_branch_pipeline,
      :dev_ee_branch_pipeline,
      :dev_ce_nightly_pipeline,
      :dev_ee_nightly_pipeline,
      :dev_auto_deploy_pipeline,
      :dev_ce_branch_pipeline_by_schedule,
      :dev_ee_branch_pipeline_by_schedule,
      :dev_ce_rc_pipeline,
      :dev_ee_rc_pipeline,
      :dev_ce_tag_pipeline,
      :dev_ee_tag_pipeline,
      # Pipelines in security repo
      :security_ce_branch_pipeline,
      :security_ee_branch_pipeline,
      # Pipelines in mirror repo
      :mirror_ce_branch_pipeline_by_trigger,
      :mirror_ee_branch_pipeline_by_trigger,
      :mirror_ee_branch_pipeline_by_trigger_with_cache_update,
      :mirror_cache_update_pipeline_by_schedule,
      # Pipelines in forks
      :fork_ce_branch_pipeline,
      :fork_ee_branch_pipeline,
    ].freeze
    def initialize; end

    def project_path
      @project_path ||= Gitlab::Util.get_env('CI_PROJECT_PATH')
    end

    def project_branch
      @project_branch ||= Gitlab::Util.get_env('CI_COMMIT_BRANCH')
    end

    def project_tag
      @project_tag ||= Gitlab::Util.get_env('CI_COMMIT_TAG')
    end

    def pipeline_source
      @pipeline_source ||= case Gitlab::Util.get_env('CI_PIPELINE_SOURCE')
                           when 'trigger', 'pipeline'
                             'trigger'
                           when 'schedule'
                             'schedule'
                           end
    end

    def project_type
      @project_type ||= case project_path
                        when 'gitlab-org/omnibus-gitlab'
                          :canonical
                        when 'gitlab/omnibus-gitlab'
                          :dev
                        when 'gitlab-org/security/omnibus-gitlab'
                          :security
                        when 'gitlab-org/build/omnibus-gitlab-mirror'
                          :mirror
                        else
                          :fork
                        end
    end

    def ee_pipeline?
      Build::Check.is_ee?
    end

    def nightly_pipeline?
      Build::Check.is_nightly?
    end

    def auto_deploy_pipeline?
      Build::Check.is_auto_deploy_tag?
    end

    def rc_pipeline?
      Build::Check.is_rc_tag?
    end

    def one_off_pipelines
      if Gitlab::Util.get_env('DEPS_PIPELINE')
        :deps_pipeline
      elsif Gitlab::Util.get_env('CACHE_UPDATE')
        :cache_update_pipeline
      elsif Gitlab::Util.get_env('DEPENDENCY_SCANNING')
        :dependency_scanning_pipeline
      end
    end

    def branch_pipelines
      return unless project_branch

      if project_branch.start_with?('docs-') || project_branch.end_with?('-docs')
        :docs_pipeline
      elsif project_branch.start_with?('deps')
        :deps_branch_pipeline
      elsif ee_pipeline?
        nightly_pipeline? ? :ee_nightly_pipeline : :ee_branch_pipeline
      else
        nightly_pipeline? ? :ce_nightly_pipeline : :ce_branch_pipeline
      end
    end

    def tag_pipelines
      return unless project_tag

      if auto_deploy_pipeline?
        :auto_deploy_pipeline
      elsif ee_pipeline?
        rc_pipeline? ? :ee_rc_pipeline : :ee_tag_pipeline
      else
        rc_pipeline? ? :ce_rc_pipeline : :ce_tag_pipeline
      end
    end

    def base_pipeline_type
      @base_pipeline_type ||= one_off_pipelines || branch_pipelines || tag_pipelines
    end

    def pipeline_type
      @pipeline_type ||= begin
        components = [project_type, base_pipeline_type]
        components << "by_#{pipeline_source}" if pipeline_source
        components.join('_').to_sym
      end
    end

    def valid_pipeline?
      VALID_PIPELINE_TYPES.include?(pipeline_type)
    end

    def templates
      {
        stages: %w[
          check
          prepare
          test
          post-test
          review
          package-and-qa
          package
          image
          staging-upload
          release
          notification
          other
        ]
      }
    end

    def pipeline_jobs
      return unless valid_pipeline?

      results = CI::Jobs.list.select do |job, details|
        details[:pipeline_types].include?(pipeline_type)
      end

      results.each do |job, details|
        details.delete(:pipeline_types)
      end

      results
    end

    def generate_ci_config
      puts "Pipeline type detected as #{pipeline_type}"
      jobs = pipeline_jobs

      raise "Pipeline type #{pipeline_type} is invalid and does not have jobs." if jobs.nil?

      pipeline = templates.merge(jobs)

      File.write('generated_ci_config.yml', pipeline.deep_stringify_keys.to_yaml(Indent: 2))
    end
  end
end
