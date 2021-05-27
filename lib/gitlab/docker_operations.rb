require 'docker'

require_relative "util.rb"

class DockerOperations
  def self.set_timeout
    timeout = Gitlab::Util.get_env('DOCKER_TIMEOUT') || 1200
    Docker.options = { read_timeout: timeout, write_timeout: timeout }
  end

  def self.build(location, image, tag, dockerfile: nil)
    set_timeout
    opts = { t: "#{image}:#{tag}", pull: true }
    opts[:dockerfile] = dockerfile if dockerfile

    Docker::Image.build_from_dir(location.to_s, opts) do |chunk|
      if (log = JSON.parse(chunk)) && log.key?("stream")
        puts log["stream"]
      end
    end
  end

  # context - The Docker context to build the image
  # image - Can be one of:
  #   1. gitlab/gitlab-{ce,ee}
  #   2. gitlab/gitlab-{ce,ee}-qa
  #   3. omnibus-gitlab/gitlab-{ce,ee}
  # tag - Can be one of:
  #   1. latest - for GitLab images
  #   2. ce-latest or ee-latest - for GitLab QA images
  #   3. any other valid docker tag
  # dockerfile - Location of the Dockerfile relative to `context` (or absolute).
  def self.build_and_push_with_kaniko(context, image, tag, dockerfile: nil)
    kaniko_cmd = %W[/kaniko/executor --context=#{context} --dockerfile=#{dockerfile} --destination=#{image}:#{tag}]
    puts "Running `#{kaniko_cmd.join(' ')}`."
    Kernel.system(*kaniko_cmd, exception: true)
  end

  def self.build_with_kaniko(context, image, tag, dockerfile: nil)
    kaniko_cmd = %W[/kaniko/executor --context=#{context} --dockerfile=#{dockerfile} --destination=#{image}:#{tag} --no-push]
    puts "Running `#{kaniko_cmd.join(' ')}`."
    Kernel.system(*kaniko_cmd, exception: true)
  end

  def self.authenticate(username = Gitlab::Util.get_env('DOCKERHUB_USERNAME'), password = Gitlab::Util.get_env('DOCKERHUB_PASSWORD'), serveraddress = "")
    Docker.authenticate!(username: username, password: password, serveraddress: serveraddress)
  end

  def self.authenticate_with_kaniko(username = Gitlab::Util.get_env('DOCKERHUB_USERNAME'), password = Gitlab::Util.get_env('DOCKERHUB_PASSWORD'), serveraddress = "https://index.docker.io/v1/")
    FileUtils.mkdir_p('/kaniko/.docker')
    File.write('/kaniko/.docker/config.json', %({"auths":{"#{serveraddress}":{"auth":"#{Base64.strict_encode64("#{username}:#{password}")}"}}}))
  end

  def self.get(namespace, tag)
    set_timeout
    Docker::Image.get("#{namespace}:#{tag}")
  end

  def self.push(namespace, tag)
    set_timeout
    image = get(namespace, tag)
    image.push(Docker.creds, repo_tag: "#{namespace}:#{tag}") do |chunk|
      puts chunk
    end
  end

  def self.tag(initial_namespace, new_namespace, initial_tag, new_tag)
    set_timeout
    image = get(initial_namespace, initial_tag)
    image.tag(repo: new_namespace, tag: new_tag, force: true)
  end

  # namespace - registry project. Can be one of:
  # 1. gitlab/gitlab-{ce,ee}
  # 2. gitlab/gitlab-{ce,ee}-qa
  # 3. omnibus-gitlab/gitlab-{ce,ee}
  #
  # initial_tag - specifies the tag used while building the image. Can be one of:
  # 1. latest - for GitLab images
  # 2. ce-latest or ee-latest - for GitLab QA images
  # 3. any other valid docker tag
  #
  # new_tag - specifies the new tag for the existing image
  def self.tag_and_push(initial_namespace, new_namespace, initial_tag, new_tag)
    tag(initial_namespace, new_namespace, initial_tag, new_tag)
    push(new_namespace, new_tag)
  end
end
