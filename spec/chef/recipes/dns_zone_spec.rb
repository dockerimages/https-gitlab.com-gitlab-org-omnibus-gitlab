require 'chef_helper'

describe 'gitlab::dns_zone' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  it 'create the correct zone file' do
    expected_contents = File.read(File.join(__dir__, '../../..', 'spec/fixtures/cookbooks/test_gitlab/files/fake_dns_zone.txt'))
    expect(chef_run).to render_file('/var/opt/gitlab/dns.zone').with_content(expected_contents)
  end
end
