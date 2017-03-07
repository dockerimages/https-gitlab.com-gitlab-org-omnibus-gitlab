require 'chef_helper'

describe 'gitlab::gitlab-pages' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with defaults' do
    before do
      stub_gitlab_rb(pages_external_url: 'https://pages.example.com')
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-proxy="localhost:8090"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-uid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-gid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-root="/var/opt/gitlab/gitlab-rails/shared/pages"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-domain="pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-redirect-http=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-use-http2=true})

      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-http})
      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-https})
      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-cert})
      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-key})
      expect(chef_run).to_not render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-metrics-address})
    end
  end

  context 'with user settings' do
    before do
      stub_gitlab_rb(
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: {
          metrics_address: 'localhost:1234',
          redirect_http: false,
          external_https: 'external_pages.example.com',
          cert: '/etc/gitlab/pages.crt'
        }
      )
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-proxy="localhost:8090"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-uid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-gid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-root="/var/opt/gitlab/gitlab-rails/shared/pages"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-domain="pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-redirect-http=false})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-use-http2=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-metrics-address="localhost:1234"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-cert="\/etc\/gitlab\/pages.crt"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-https="external_pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-key})
    end
  end

  context 'no external_url specified' do
    before do
      stub_gitlab_rb(
        gitlab_pages: {
          enable: true,
          metrics_address: 'localhost:1234',
          redirect_http: false,
          external_https: 'external_pages.example.com',
          cert: '/etc/gitlab/pages.crt'
        }
      )
    end
    it 'correctly renders the pages service run file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-proxy="localhost:8090"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-uid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-daemon-gid})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-root="/var/opt/gitlab/gitlab-rails/shared/pages"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-pages-domain=""})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-redirect-http=false})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-use-http2=true})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-metrics-address="localhost:1234"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-cert="\/etc\/gitlab\/pages.crt"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-listen-https="external_pages.example.com"})
      expect(chef_run).to render_file("/opt/gitlab/sv/gitlab-pages/run").with_content(%r{-root-key})
    end
  end

  context 'with empty host URI' do
    before do
      stub_gitlab_rb(pages_external_url: '')
    end

    it 'raises error' do
      expect{ chef_run }.to raise_error("GitLab Pages external URL must include a schema and FQDN, e.g. http://pages.example.com/")
    end

  end

  context 'with incorrect host URI scheme' do
    before do
      stub_gitlab_rb(pages_external_url: 'tcp://abcde.fghi')
    end

    it 'raises error' do
      expect{ chef_run }.to raise_error("Unsupported GitLab Pages external URL scheme: tcp")
    end
  end

  context 'with incorrect host URI path' do
    before do
      stub_gitlab_rb(pages_external_url: 'https://example.com/qwer')
    end

    it 'raises error' do
      expect{ chef_run }.to raise_error("Unsupported GitLab Pages external URL path: /qwer")
    end
  end

  context 'gitlab-pages disabled' do
    before do
      stub_gitlab_rb(
        pages_external_url: 'https://pages.example.com',
        gitlab_pages: { enable: false }
      )
    end

    it 'correctly renders the pages service run file' do
      expect(chef_run).not_to render_file("/opt/gitlab/sv/gitlab-pages/run")
    end
  end
end
