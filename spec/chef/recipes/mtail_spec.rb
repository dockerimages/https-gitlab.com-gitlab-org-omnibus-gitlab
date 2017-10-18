require 'chef_helper'

describe 'gitlab::mtail' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when mtail is disabled locally' do
    before do
      stub_gitlab_rb(
        mtail: { enable: false }
      )
    end

    it 'defaults the mtail to being disabled' do
      expect(node['gitlab']['mtail']['enable']).to eq false
    end

    it 'allows mtail to be explicitly enabled' do
      stub_gitlab_rb(mtail: { enable: true })

      expect(node['gitlab']['mtail']['enable']).to eq true
    end
  end

  context 'when mtail is enabled' do
    let(:config_template) { chef_run.template('/var/log/gitlab/mtail/config') }

    before do
      stub_gitlab_rb(
        mtail: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'mtail', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload mtail svlogd configuration]')

      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/mtail/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/mtail/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/mtail').with(
        owner: 'gitlab-redis',
        group: nil,
        mode: '0700'
      )
    end

    it 'sets default flags' do
      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/run')
        .with_content(/address=localhost/)
      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/run')
        .with_content(/port=3903/)
      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/run')
        .with_content(%r{progs=/var/log/gitlab/unicorn/unicorn_stderr.log,/var/log/gitlab/sidekiq/current})
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        mtail: {
          log_directory: 'foo',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        mtail: {
          flags: {
            'port' => '39030'
          },
          listen_address: 'user-test',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/run')
        .with_content(/address=user-test/)
      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/run')
        .with_content(/port=39030/)
      expect(chef_run).to render_file('/opt/gitlab/sv/mtail/run')
        .with_content(%r{redis.addr=/tmp/socket})
    end
  end
end
