require 'serverspec'

set :backend, :exec

def external_url
  return ENV['EXTERNAL_URL'] if ENV.key?('EXTERNAL_URL')

  begin
    data = JSON.parse(File.read("/opt/gitlab/embedded/nodes/#{`hostname -f`.chomp}.json"))
  rescue JSON::ParserError, Errno::ENOENT
    return ''
  end

  data['normal']['gitlab']['external-url']
end
