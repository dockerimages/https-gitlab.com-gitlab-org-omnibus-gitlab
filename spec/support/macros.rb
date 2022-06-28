require 'openssl'

module GitlabSpec
  module Macros
    def stub_gitlab_rb(config)
      config.each do |key, value|
        value = Mash.from_hash(value) if value.is_a?(Hash)
        allow(Gitlab).to receive(:[]).with(key.to_s).and_return(value)
      end
    end

    def stub_default_should_notify?(value)
      allow(File).to receive(:symlink?).and_return(value)
      allow_any_instance_of(OmnibusHelper).to receive(:success?).and_return(value)
    end

    # @param [Boolean] value status whether it is listening or not
    def stub_default_not_listening?(value)
      allow_any_instance_of(OmnibusHelper).to receive(:not_listening?).and_return(false)
    end

    # @param [String] service internal name of the service (on-disk)
    # @param [Boolean] value status command succeed?
    def stub_service_success_status(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(value)
    end

    # @param [String] service internal name of the service (on-disk)
    # @param [Boolean] value status command failed?
    def stub_service_failure_status(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:failure?).with("/opt/gitlab/init/#{service} status").and_return(value)
    end

    def stub_should_notify?(service, value)
      allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(value)
      stub_service_success_status(service, value)
    end

    # @param [String] service internal name of the service (on-disk)
    # @param [Boolean] value status whether it is listening or not
    def stub_not_listening?(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:not_listening?).with(service).and_return(value)
    end

    def stub_expected_owner?
      allow_any_instance_of(OmnibusHelper).to receive(:expected_owner?).and_return(true)
    end

    def stub_env_var(var, value)
      allow(ENV).to receive(:[]).with(var).and_return(value)
    end

    def stub_is_package_version(package, value = nil)
      allow(File).to receive(:read).with('VERSION').and_return(value ? "1.2.3-#{package}" : '1.2.3')
    end

    def stub_default_package_version
      allow(File).to receive(:read).and_call_original
      allow(ENV).to receive(:[]).and_call_original
      stub_is_package_version('ce')
    end

    def stub_is_package_env(package, value)
      stub_env_var(package, value.nil? ? '' : value.to_s)
    end

    def stub_is_package(package, value)
      stub_is_package_version(package, value)
      stub_is_package_env(package, value)
    end

    def stub_is_ee_version(value)
      stub_is_package_version('ee', value)
    end

    def stub_is_ee_env(value)
      stub_is_package_env('ee', value)
    end

    def stub_is_ee(value)
      stub_is_package('ee', value)
      # Auto-deploys can not be non-EE. So, stubbing it to false for CE builds.
      # However, since not all EE builds need to be auto-deploys, stubbing it
      # to true needs to be done in a case-by-case manner.
      stub_is_auto_deploy(value) unless value
    end

    def stub_is_auto_deploy(value)
      allow(Build::Check).to receive(:is_auto_deploy?).and_return(value)
    end

    def converge_config(*recipes, is_ee: false)
      Gitlab[:node] = nil
      Services.add_services('gitlab-ee', Services::EEServices.list) if is_ee
      config_recipe = is_ee ? 'gitlab-ee::config' : 'gitlab::config'
      ChefSpec::SoloRunner.converge(config_recipe, *recipes)
    end

    # Return the full path for the spec fixtures folder
    # @return [String] full path
    def fixture_path
      File.join(__dir__, '../chef/fixtures')
    end

    def get_rendered_toml(chef_run, path)
      template = chef_run.template(path)
      content = ChefSpec::Renderer.new(chef_run, template).content
      TomlRB.parse(content, symbolize_keys: true)
    end

    def stub_pipeline(pipeline_type)
      pipeline_details = {
        # Pipelines in canonical repo
        canonical_deps_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_PIPELINE_SOURCE' => 'schedule',
          'DEPS_PIPELINE' => 'true',
        },
        canonical_cache_update_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_PIPELINE_SOURCE' => 'schedule',
          'CACHE_UPDATE' => 'true',
        },
        canonical_dependency_scanning_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_PIPELINE_SOURCE' => 'schedule',
          'DEPENDENCY_SCANNING' => 'true',
        },
        canonical_docs_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'foobar-docs',
        },
        canonical_ce_branch_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'feature-branch',
        },
        canonical_ce_branch_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'CI_PIPELINE_SOURCE' => 'schedule',
        },
        canonical_ee_branch_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'feature-branch',
          'ee' => 'true'
        },
        canonical_ee_branch_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'CI_PIPELINE_SOURCE' => 'schedule',
          'ee' => 'true'
        },
        canonical_ce_tag_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_COMMIT_TAG' => '15.1.0+ce.0'
        },
        canonical_ee_tag_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab-org/omnibus-gitlab',
          'CI_COMMIT_TAG' => '15.1.0+ee.0'
        },
        # Pipelines in dev repo
        dev_ce_branch_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'feature-branch',
        },
        dev_ee_branch_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'feature-branch',
          'ee' => 'true'
        },
        dev_ce_nightly_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'NIGHTLY' => 'true',
        },
        dev_ee_nightly_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'NIGHTLY' => 'true',
          'ee' => 'true'
        },
        dev_ce_nightly_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'CI_PIPELINE_SOURCE' => 'schedule',
          'NIGHTLY' => 'true',
        },
        dev_ee_nightly_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'CI_PIPELINE_SOURCE' => 'schedule',
          'NIGHTLY' => 'true',
          'ee' => 'true'
        },
        dev_ce_branch_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'CI_PIPELINE_SOURCE' => 'schedule',
        },
        dev_ee_branch_pipeline_by_schedule: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'master',
          'CI_PIPELINE_SOURCE' => 'schedule',
          'ee' => 'true'
        },
        dev_auto_deploy_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_TAG' => '15.2.202206232020+1e26e8ce063.3cfd7e47b1d'
        },
        dev_ce_rc_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_TAG' => '15.1.0+rc42.ce.0'
        },
        dev_ee_rc_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_TAG' => '15.1.0+rc42.ee.0'
        },
        dev_ce_tag_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_TAG' => '15.1.0+ce.0'
        },
        dev_ee_tag_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab/omnibus-gitlab',
          'CI_COMMIT_TAG' => '15.1.0+ee.0'
        },
        # Pipelines in security repo
        security_ce_branch_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab-org/security/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'feature-branch',
        },
        security_ee_branch_pipeline: {
          'CI_PROJECT_PATH' => 'gitlab-org/security/omnibus-gitlab',
          'CI_COMMIT_BRANCH' => 'feature-branch',
          'ee' => 'true'
        },
        # Pipelines in mirror repo
        mirror_ce_branch_pipeline_by_trigger: {
          'CI_PROJECT_PATH' => 'gitlab-org/build/omnibus-gitlab-mirror',
          'CI_COMMIT_BRANCH' => 'feature-branch',
          'CI_PIPELINE_SOURCE' => 'pipeline'
        },
        mirror_ee_branch_pipeline_by_trigger: {
          'CI_PROJECT_PATH' => 'gitlab-org/build/omnibus-gitlab-mirror',
          'CI_COMMIT_BRANCH' => 'feature-branch',
          'CI_PIPELINE_SOURCE' => 'pipeline',
          'ee' => 'true'
        },
        # Pipelines in forks
        fork_ce_branch_pipeline: {
          'CI_PROJECT_PATH' => 'johndoe/omnibus-gitlab-mirror',
          'CI_COMMIT_BRANCH' => 'feature-branch',
        },
        fork_ee_branch_pipeline: {
          'CI_PROJECT_PATH' => 'johndoe/omnibus-gitlab-mirror',
          'CI_COMMIT_BRANCH' => 'feature-branch',
          'ee' => 'true'
        },
      }

      allow(ENV).to receive(:[]).with(/CI_/).and_return(nil)
      pipeline_details[pipeline_type].each do |key, value|
        stub_env_var(key, value)
      end
    end
  end
end
