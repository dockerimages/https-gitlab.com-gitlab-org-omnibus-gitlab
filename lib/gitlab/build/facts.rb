module Build
  class Facts
    class << self
      def generate
        generate_tag_files
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
    end
  end
end
