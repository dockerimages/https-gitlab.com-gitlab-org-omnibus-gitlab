require 'docker'
require_relative '../docker_operations'
require_relative '../build/qa'
require_relative '../build/check'
require_relative '../build/info'
require_relative '../build/gitlab_image'
require_relative '../build/qa_image'
require_relative '../build/rat'
require_relative '../build/get'
require_relative "../util.rb"

namespace :qa do
  desc "Build QA Docker image"
  task :build do
    Gitlab::Util.section('qa:build') do
      DockerOperations.build_with_kaniko(
        Build::QA.get_gitlab_repo,
        Build::QAImage.gitlab_registry_image_address,
        'latest',
        dockerfile: 'qa/Dockerfile'
      )
    end
  end

  namespace :push do
    # Only runs on dev.gitlab.org
    desc "Push unstable or auto-deploy version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :staging do
      Gitlab::Util.section('qa:push:staging') do
        tag = Build::Check.is_auto_deploy? ? Build::Info.major_minor_version_and_rails_ref : Build::Info.gitlab_version
        Build::QAImage.build_and_push_with_kaniko(
          Build::QA.get_gitlab_repo,
          [
            "#{Build::QAImage.gitlab_registry_image_address}:#{tag}",
            "#{Build::QAImage.gitlab_registry_image_address}:#{Build::Info.commit_sha}"
          ],
          dockerfile: 'qa/Dockerfile')
      end
    end

    desc "Push stable version of gitlab-{ce,ee}-qa to the GitLab registry and Docker Hub"
    task :stable do
      Gitlab::Util.section('qa:push:stable') do
        # Allows to have gitlab/gitlab-{ce,ee}-qa:10.2.0-ee without the build number
        Build::QAImage.build_and_push_with_kaniko(
          Build::QA.get_gitlab_repo,
          [
            "#{Build::QAImage.gitlab_registry_image_address}:#{Build::Info.gitlab_version}",
            "#{Build::QAImage.dockerhub_image_name}:#{Build::Info.gitlab_version}"
          ],
          dockerfile: 'qa/Dockerfile')
      end
    end

    desc "Push rc version of gitlab-{ce,ee}-qa to Docker Hub"
    task :rc do
      Gitlab::Util.section('qa:push:rc') do
        next unless Build::Check.is_latest_tag?

        Build::QAImage.build_and_push_with_kaniko(
          Build::QA.get_gitlab_repo,
          "#{Build::QAImage.dockerhub_image_name}:rc",
          dockerfile: 'qa/Dockerfile')
      end
    end

    desc "Push nightly version of gitlab-{ce,ee}-qa to Docker Hub"
    task :nightly do
      Gitlab::Util.section('qa:push:nightly') do
        next unless Build::Check.is_nightly?

        Build::QAImage.build_and_push_with_kaniko(
          Build::QA.get_gitlab_repo,
          "#{Build::QAImage.dockerhub_image_name}:nightly",
          dockerfile: 'qa/Dockerfile')
      end
    end

    desc "Push latest version of gitlab-{ce,ee}-qa to Docker Hub"
    task :latest do
      Gitlab::Util.section('qa:push:latest') do
        next unless Build::Check.is_latest_stable_tag?

        Build::QAImage.build_and_push_with_kaniko(
          Build::QA.get_gitlab_repo,
          "#{Build::QAImage.dockerhub_image_name}:latest",
          dockerfile: 'qa/Dockerfile')
      end
    end

    desc "Push triggered version of gitlab-{ce,ee}-qa to the GitLab registry"
    task :triggered do
      Gitlab::Util.section('qa:push:triggered') do
        Build::QAImage.build_and_push_with_kaniko(
          Build::QA.get_gitlab_repo,
          "#{Build::QAImage.gitlab_registry_image_address}:#{Build::Info.docker_tag}",
          dockerfile: 'qa/Dockerfile')
      end
    end
  end

  desc "Run QA letsencrypt tests"
  task :test_letsencrypt do
    Gitlab::Util.section('qa:test_letsencrypt') do
      Gitlab::Util.set_env_if_missing('CI_REGISTRY_IMAGE', 'registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror')
      image_address = Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)
      Dir.chdir('letsencrypt-test') do
        system({ 'IMAGE' => image_address }, './test.sh')
      end
    end
  end

  namespace :rat do
    desc "Trigger a RAT pipeline"
    task :trigger do
      Gitlab::Util.section('qa:rat:validate') do
        Build::RAT::TriggerPipeline.invoke!.wait!(timeout: 3600 * 4)
      end
    end

    desc "Trigger a RAT pipeline using nightly package"
    task :nightly do
      Gitlab::Util.section('qa:rat:validate') do
        Build::RAT::NightlyPipeline.invoke!.wait!(timeout: 3600 * 4)
      end
    end

    desc "Trigger a RAT pipeline using tag package"
    task :tag do
      Gitlab::Util.section('qa:rat:validate') do
        Build::RAT::TagPipeline.invoke!.wait!(timeout: 3600 * 4)
      end
    end
  end

  namespace :get do
    namespace :geo do
      desc 'Trigger a GET Geo validation'
      task :trigger do
        Gitlab::Util.section('qa:get:geo:validate') do
          Build::Get::Geo::TriggerPipeline.invoke!.wait!(timeout: 3600 * 4)
        end
      end
    end
  end
end
