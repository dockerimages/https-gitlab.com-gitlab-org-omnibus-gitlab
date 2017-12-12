require 'net/http'
require 'json'
require 'cgi'

module Build
  QA_PROJECT_PATH = 'gitlab-org/gitlab-qa'.freeze

  class Trigger
    TOKEN = ENV['QA_TRIGGER_TOKEN']

    def initialize(image: nil)
      @uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(Build::QA_PROJECT_PATH)}/trigger/pipeline")
      @params = env_params.merge(token: TOKEN).merge(RELEASE: image)
    end

    def invoke!
      res = Net::HTTP.post_form(@uri, @params)
      id = JSON.parse(res.body)['id']

      raise "Trigger failed! The response from the trigger is: #{res.body}" unless id

      puts "Triggered https://gitlab.com/#{Build::QA_PROJECT_PATH}/pipelines/#{id}"
      Build::Pipeline.new(id)
    end

    private

    def env_params
      {
        "ref" => "master"
      }
    end
  end

  class Pipeline
    INTERVAL = 60 # seconds
    MAX_DURATION = 3600 * 3 # 3 hours

    def initialize(id)
      @start = Time.now.to_i
      @uri = URI("https://gitlab.com/api/v4/projects/#{CGI.escape(Build::QA_PROJECT_PATH)}/pipelines/#{id}")
    end

    def wait!
      loop do
        raise 'Pipeline timeout!' if timeout?

        case status
        when :created, :pending, :running
          puts "Waiting another #{INTERVAL} seconds ..."
          sleep INTERVAL
        when :success
          return true
        else
          return false
        end

        STDOUT.flush
      end
    end

    def timeout?
      Time.now.to_i > (@start + MAX_DURATION)
    end

    def status
      req = Net::HTTP::Get.new(@uri)
      req['PRIVATE-TOKEN'] = ENV['QA_ACCESS_TOKEN']

      res = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      JSON.parse(res.body)['status'].to_s.to_sym
    end
  end
end
