require 'chef_helper'

describe 'gitlab::webdriver-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when webdriver-exporter is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/webdriver-exporter/config') }

    before do
      stub_gitlab_rb(
        webdriver_exporter: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'webdriver-exporter', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload webdriver-exporter svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/webdriver-exporter/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/webdriver_exporter/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/webdriver-exporter/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/webdriver-exporter/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/webdriver-exporter').with(
        owner: 'gitlab-webdriver',
        group: nil,
        mode: '0700'
      )
    end

    it 'sets default flags' do
      expect(chef_run).to render_file('/opt/gitlab/sv/webdriver-exporter/run')
        .with_content(/web.listen-address=localhost:9156/)
      expect(chef_run).to render_file('/opt/gitlab/sv/webdriver-exporter/run')
        .with_content(%r{webdriver.addr=unix:///var/opt/gitlab/webdriver/webdriver.socket})
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        webdriver_exporter: {
          log_directory: 'foo',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/webdriver-exporter/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        webdriver_exporter: {
          flags: {
            'webdriver.addr' => '/tmp/socket'
          },
          listen_address: 'localhost:9900',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/webdriver-exporter/run')
        .with_content(/web.listen-address=localhost:9900/)
      expect(chef_run).to render_file('/opt/gitlab/sv/webdriver-exporter/run')
        .with_content(%r{webdriver.addr=/tmp/socket})
    end
  end
end
