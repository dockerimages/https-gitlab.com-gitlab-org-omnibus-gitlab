require 'chef_helper'

describe 'gitlab::puma' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(templatesymlink),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(puma: { enable: true })
  end

  context 'when puma is enabled' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).not_to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/rm \/run\/gitlab\/puma/)
          expect(content).to match(/mkdir -p \/run\/gitlab\/puma/)
          expect(content).to match(/chmod 0700 \/run\/gitlab\/puma/)
          expect(content).to match(/chown git \/run\/gitlab\/puma/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/puma\'/)
        }
    end

    it 'renders the puma.rb file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(/^require_relative \"\/opt\/gitlab\/embedded\/service\/gitlab-rails\/lib\/gitlab\/cluster\/lifecycle_events\"/)
      }
    end
  end

  context 'with custom runtime_dir' do
    before do
      stub_gitlab_rb(runtime_dir: '/tmp/test-dir')
    end

    it 'uses the user-specific runtime_dir' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(%r(export prometheus_run_dir='/tmp/test-dir/gitlab/puma'))
          expect(content).to match(%r(mkdir -p /tmp/test-dir/gitlab/puma))
        }
    end
  end
end

describe 'gitlab::puma' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(templatesymlink),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-no-run-tmpfs.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(puma: { enable: true })
  end

  context 'when puma is enabled on a node with no /run or /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/mkdir -p \/run\/gitlab\/puma/)
        }
    end
  end
end

describe 'gitlab::puma' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(templatesymlink),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-docker.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(puma: { enable: true })
  end

  context 'when puma is enabled on a node with a /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'puma', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/puma/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/mkdir -p \/dev\/shm\/gitlab\/puma/)
        }
    end
  end
end
