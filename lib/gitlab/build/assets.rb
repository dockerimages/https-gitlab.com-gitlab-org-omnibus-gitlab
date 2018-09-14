require 'open-uri'

module Build
  class Assets
    class << self
      def fetch(destination, type, version)
        url = "https://gitlab.com/api/v4/projects/gitlab-org%2F#{type}/jobs/artifacts/#{version}/download?job=gitlab:assets:compile"
        uri = URI(url)
        File.open(destination, 'wb') do |file|
          IO.copy_stream(open(uri, 'rb'), file)
        end
      end
    end
  end
end
