require 'spec_helper'
require 'ci/pipeline'

RSpec.describe CI::Pipeline do
  let(:subject) { described_class.new }
  let(:common_mr_jobs) do
    [
      'rubocop',
      'yard',
      'docs-lint links',
      'docs-lint markdown',
      'generate-facts',
      'validate-packer-changes',
      'AmazonLinux-2-knapsack',
      'CentOS-7-knapsack',
      'CentOS-8-knapsack',
      'Debian-9-knapsack',
      'Debian-10-knapsack',
      'Debian-11-knapsack',
      'OpenSUSE-15.3-knapsack',
      'Ubuntu-16.04-knapsack',
      'Ubuntu-18.04-knapsack',
      'Ubuntu-20.04-knapsack',
      'AmazonLinux-2-specs',
      'CentOS-7-specs',
      'CentOS-8-specs',
      'Debian-9-specs',
      'Debian-10-specs',
      'Debian-11-specs',
      'OpenSUSE-15.3-specs',
      'Ubuntu-16.04-specs',
      'Ubuntu-18.04-specs',
      'Ubuntu-20.04-specs',
      'build library specs',
      'update-knapsack',
    ]
  end
  let(:team_mr_jobs) do
    extra_jobs = [
      'danger-review',
      'check-for-sha-in-mirror',
      'review-docs-cleanup',
      'review-docs-deploy',
      'Trigger:ce-package',
      'Trigger:ee-package',
    ]

    common_mr_jobs.concat(extra_jobs)
  end
  let(:common_dev_branch_jobs) do
    [
      'fetch-assets',
      'generate-facts',
      'AmazonLinux-2-branch',
      'AmazonLinux-2-arm-branch',
      'CentOS-7-branch',
      'CentOS-8-branch',
      'CentOS-8-arm-branch',
      'Debian-9-branch',
      'Debian-10-branch',
      'Debian-10-arm-branch',
      'Debian-11-branch',
      'Debian-11-arm-branch',
      'OpenSUSE-15.3-branch',
      'OpenSUSE-15.3-arm-branch',
      'Ubuntu-16.04-branch',
      'Ubuntu-18.04-branch',
      'Ubuntu-20.04-branch',
      'Ubuntu-20.04-arm-branch',
      'Docker-branch',
      'Docker-QA-branch',
    ]
  end
  let(:dev_ce_branch_jobs) do
    common_dev_branch_jobs.concat(['Raspberry-Pi-2-Buster-branch'])
  end
  let(:dev_ee_branch_jobs) do
    extra_jobs = [
      'SLES-12.5-branch',
      'SLES-15.2-branch',
      'CentOS-8-fips-branch',
      'Ubuntu-18.04-fips-branch',
      'Ubuntu-20.04-fips-branch',
    ]

    common_dev_branch_jobs.concat(extra_jobs)
  end
  let(:common_dev_nightly_jobs) do
    [
      'Ubuntu-16.04-nightly-upload',
      'Ubuntu-18.04-nightly-upload',
      'Ubuntu-20.04-nightly-upload',
    ]
  end
  let(:dev_ce_nightly_jobs) do
    common_dev_nightly_jobs.concat(dev_ce_branch_jobs)
  end
  let(:dev_ee_nightly_jobs) do
    common_dev_nightly_jobs.concat(dev_ee_branch_jobs)
  end
  let(:common_mirror_jobs) do
    [
      'generate-facts',
      'fetch-assets',
      'Trigger:package',
      'Trigger:docker',
      'Trigger:QA-docker',
      'package_size_check',
      'qa',
      'letsencrypt-test',
      'RAT',
      'GET:Geo'
    ]
  end
  let(:mirror_ee_jobs) do
    extra_jobs = [
      'Trigger:package:fips',
      'RAT:FIPS'
    ]

    common_mirror_jobs.concat(extra_jobs)
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    stub_env_var('CI_COMMIT_BRANCH', 'feature-foobar')
  end

  describe '#project_type' do
    RSpec.shared_examples 'detects project type' do |ci_project_path, type|
      it "detects project type as #{type} when project path is #{ci_project_path}" do
        stub_env_var('CI_PROJECT_PATH', ci_project_path)

        expect(subject.project_type).to eq(type)
      end
    end

    include_examples 'detects project type', 'gitlab-org/omnibus-gitlab', :canonical
    include_examples 'detects project type', 'gitlab/omnibus-gitlab', :dev
    include_examples 'detects project type', 'gitlab-org/security/omnibus-gitlab', :security
    include_examples 'detects project type', 'gitlab-org/build/omnibus-gitlab-mirror', :mirror
  end

  describe '#base_pipeline_type' do
    it 'detects deps pipeline' do
      stub_pipeline(:canonical_deps_pipeline_by_schedule)

      expect(subject.base_pipeline_type).to eq(:deps_pipeline)
    end

    it 'detects cache update pipeline' do
      stub_pipeline(:canonical_cache_update_pipeline_by_schedule)

      expect(subject.base_pipeline_type).to eq(:cache_update_pipeline)
    end

    it 'detects dependency scanning pipeline' do
      stub_pipeline(:canonical_dependency_scanning_pipeline_by_schedule)

      expect(subject.base_pipeline_type).to eq(:dependency_scanning_pipeline)
    end

    describe 'branch pipeline' do
      before do
        stub_env_var('CI_COMMIT_BRANCH', 'master')
      end

      describe 'docs pipeline' do
        it 'detects docs branch pipeline with "docs-" prefix' do
          stub_pipeline(:canonical_docs_pipeline)

          expect(subject.base_pipeline_type).to eq(:docs_pipeline)
        end

        it 'detects docs branch pipeline with "-docs" suffix' do
          stub_pipeline(:canonical_docs_pipeline)
          stub_env_var('CI_COMMIT_BRANCH', 'foo-docs')

          expect(subject.base_pipeline_type).to eq(:docs_pipeline)
        end
      end

      describe 'nightly pipeline' do
        it 'detects EE nigthly pipeline' do
          stub_pipeline(:dev_ee_nightly_pipeline)

          expect(subject.base_pipeline_type).to eq(:ee_nightly_pipeline)
        end

        it 'detects CE nigthly pipeline' do
          stub_pipeline(:dev_ce_nightly_pipeline)
          allow(Build::Check).to receive(:is_ee?).and_return(false)

          expect(subject.base_pipeline_type).to eq(:ce_nightly_pipeline)
        end
      end

      describe 'feature branch pipeline' do
        it 'detects EE pipeline' do
          stub_pipeline(:dev_ee_branch_pipeline)

          expect(subject.base_pipeline_type).to eq(:ee_branch_pipeline)
        end

        it 'detects CE pipeline' do
          stub_pipeline(:dev_ce_branch_pipeline)

          expect(subject.base_pipeline_type).to eq(:ce_branch_pipeline)
        end
      end
    end

    describe 'tag pipeline' do
      it 'detects auto-deploy pipeline' do
        stub_pipeline(:dev_auto_deploy_pipeline)
        allow(File).to receive(:read).with('VERSION').and_return('1e26e8ce0631ae6fdd5a97b4068c225f350585a6')

        expect(subject.base_pipeline_type).to eq(:auto_deploy_pipeline)
      end

      it 'detects EE RC pipeline' do
        stub_pipeline(:dev_ee_rc_pipeline)
        allow(File).to receive(:read).with('VERSION').and_return('15.1.0-rc42-ee')

        expect(subject.base_pipeline_type).to eq(:ee_rc_pipeline)
      end

      it 'detects CE RC pipeline' do
        stub_pipeline(:dev_ce_rc_pipeline)
        allow(File).to receive(:read).with('VERSION').and_return('15.1.0-rc42')

        expect(subject.base_pipeline_type).to eq(:ce_rc_pipeline)
      end

      it 'detects EE tag pipeline' do
        stub_pipeline(:dev_ee_tag_pipeline)
        allow(File).to receive(:read).with('VERSION').and_return('15.1.0-ee')

        expect(subject.base_pipeline_type).to eq(:ee_tag_pipeline)
      end

      it 'detects CE tag pipeline' do
        stub_pipeline(:dev_ce_tag_pipeline)
        allow(File).to receive(:read).with('VERSION').and_return('15.1.0')

        expect(subject.base_pipeline_type).to eq(:ce_tag_pipeline)
      end
    end

    describe '#pipeline_type' do
      before do
        stub_env_var('CI_COMMIT_BRANCH', 'foobar')
      end

      describe 'feature branch pipeline' do
        it 'detects feature branch pipeline in com' do
          stub_pipeline(:canonical_ce_branch_pipeline)

          expect(subject.pipeline_type).to eq(:canonical_ce_branch_pipeline)
        end

        it 'detects feature branch pipeline in dev' do
          stub_pipeline(:dev_ce_branch_pipeline)

          expect(subject.pipeline_type).to eq(:dev_ce_branch_pipeline)
        end

        it 'detects feature branch pipeline in security' do
          stub_pipeline(:security_ce_branch_pipeline)

          expect(subject.pipeline_type).to eq(:security_ce_branch_pipeline)
        end

        it 'detects feature branch pipeline in forks' do
          stub_pipeline(:fork_ce_branch_pipeline)

          expect(subject.pipeline_type).to eq(:fork_ce_branch_pipeline)
        end

        it 'detects multi project pipelines' do
          stub_pipeline(:mirror_ce_branch_pipeline_by_trigger)

          expect(subject.pipeline_type).to eq(:mirror_ce_branch_pipeline_by_trigger)
        end

        it 'detects nightly schedule pipelines' do
          stub_pipeline(:dev_ee_nightly_pipeline_by_schedule)

          expect(subject.pipeline_type).to eq(:dev_ee_nightly_pipeline_by_schedule)
        end
      end
    end
  end

  describe '#pipeline_jobs' do
    it 'on a team MR pipeline in canonical repo returns correct list of jobs' do
      stub_pipeline(:canonical_ce_branch_pipeline)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*team_mr_jobs)
    end

    it 'on a fork MR pipeline in canonical repo returns correct list of jobs' do
      stub_pipeline(:fork_ce_branch_pipeline)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*common_mr_jobs)
    end

    it 'on a regular CE feature branch push to dev repo returns correct list of jobs' do
      stub_pipeline(:dev_ce_branch_pipeline)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*dev_ce_branch_jobs)
    end

    it 'on a regular EE feature branch push to dev repo returns correct list of jobs' do
      stub_pipeline(:dev_ee_branch_pipeline)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*dev_ee_branch_jobs)
    end

    it 'on a CE nightly in dev repo returns correct list of jobs' do
      stub_pipeline(:dev_ce_nightly_pipeline)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*dev_ce_nightly_jobs)
    end

    it 'on a EE nightly in dev repo returns correct list of jobs' do
      stub_pipeline(:dev_ee_nightly_pipeline)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*dev_ee_nightly_jobs)
    end

    it 'on a CE trigger in mirror repo returns correct list of jobs' do
      stub_pipeline(:mirror_ce_branch_pipeline_by_trigger)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*common_mirror_jobs)
    end

    it 'on a EE trigger in mirror repo returns correct list of jobs' do
      stub_pipeline(:mirror_ee_branch_pipeline_by_trigger)

      expect(subject.pipeline_jobs.keys).to contain_exactly(*mirror_ee_jobs)
    end
  end
end
