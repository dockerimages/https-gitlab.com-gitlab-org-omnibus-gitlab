require 'chef_helper'

describe 'jaeger-agent' do
  let(:fake_jaeger_version) { '{"gitCommit":"d75eb142dbb0ce06642d7f4892c4c5c5a099d1da","GitVersion":"v1.17.0","BuildDate":"2020-04-17T16:09:14Z"}' }

  allow(VersionHelper).to receive(:version).with(/jaeger-agent version/).and_return(fake_jaeger_version)
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'by default' do
    it_behaves_like 'disabled runit service', 'jaeger-agent', 'root', 'root'
  end

  context 'when enabled' do
    before do
      stub_gitlab_rb(
        jaeger_agent: {
          enable: true,
          collector: 'jaeger-collector.jaeger-infra.svc:14250',
        }
      )
    end

    it 'creates jaeger user and group' do
      expect(chef_run).to create_account('user and group for jaeger').with(username: 'gitlab-jaeger', groupname: 'gitlab-jaeger')
    end

    it_behaves_like 'enabled runit service', 'jaeger-agent', 'root', 'root', 'gitlab-jaeger', 'gitlab-jaeger'

    it 'configures the target collector host and port' do
      expect(chef_run).to render_file('/opt/gitlab/sv/jaeger-agent/run')
        .with_content { |content|
          expect(content).to match(/--reporter.grpc.host-port=jaeger-collector.jaeger-infra.svc:14250/)
          expect(content).to match(/--jaeger.tags=$/)
        }
    end
  end

  context 'with custom tags' do
    before do
      stub_gitlab_rb(
        jaeger_agent: {
          enable: true,
          collector: 'jaeger-collector.jaeger-infra.svc:14250',
          tags: 'foo=bar,baz=qux'
        }
      )
    end

    it 'configures custom tags' do
      expect(chef_run).to render_file('/opt/gitlab/sv/jaeger-agent/run')
        .with_content { |content|
          expect(content).to match(/--reporter.grpc.host-port=jaeger-collector.jaeger-infra.svc:14250/)
          expect(content).to match(/--jaeger.tags=foo=bar,baz=qux$/)
        }
    end
  end
end
