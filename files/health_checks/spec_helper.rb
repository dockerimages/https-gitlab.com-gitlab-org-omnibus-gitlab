require 'serverspec'

set :backend, :exec

def external_url
  return ENV['EXTERNAL_URL'] if ENV.key?('EXTERNAL_URL')

  begin
    data = JSON.parse(File.read("/opt/gitlab/embedded/nodes/#{`hostname -f`.chomp}.json"))
  rescue JSON::ParserError, Errno::ENOENT
    gitlab_rb = '/etc/gitlab/gitlab.rb'
    return '' unless File.exist?(gitlab_rb)
    return File.read(gitlab_rb).lines.find { |x| x.start_with?('external_url') }.split.last.tr("'", '')
  end

  data['normal']['gitlab']['external-url']
end
