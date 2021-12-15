module Build
  class Facts
    class << self
      def generate
        generate_tag_files
        generate_env_file
      end

      def generate_tag_files
        [
          :latest_stable_tag,
          :latest_tag
        ].each do |fact|
          content = Build::Info.send(fact) # rubocop:disable GitlabSecurity/PublicSend
          File.write("build_facts/#{fact}", content) unless content.nil?
        end
      end

      def generate_env_file
        env_vars = []
        env_vars += qa_trigger_vars

        File.write("build_facts/env_vars", env_vars.join("\n"))
      end

      def qa_trigger_vars
        %W[
          QA_RELEASE=#{Build::GitlabImage.gitlab_registry_image_address(tag: Build::Info.docker_tag)}
        ]
      end
    end
  end
end
