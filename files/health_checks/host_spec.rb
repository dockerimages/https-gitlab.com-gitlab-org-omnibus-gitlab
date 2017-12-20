require 'json'
require 'serverspec'
require 'uri'

set :backend, :exec

data = JSON.parse(File.read("/opt/gitlab/embedded/nodes/#{`hostname -f`.chomp}.json"))

url = URI(data['normal']['gitlab']['external-url'])

describe host(url.host) do
  it 'is not a resolvable external_url' do
    expect(subject).to be_resolvable.by('dns')
  end
end
