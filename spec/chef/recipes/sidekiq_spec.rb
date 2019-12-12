require 'chef_helper'

describe 'gitlab::sidekiq' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with default values' do
    it 'correctly renders out the sidekiq service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run")
        .with_content { |content|
          expect(content).not_to match(/export prometheus_run_dir=\'\'/)
          expect(content).to match(/mkdir -p \/run\/gitlab\/sidekiq/)
          expect(content).to match(/rm \/run\/gitlab\/sidekiq/)
          expect(content).to match(/export DO_NOT_CLEAN_METRICS_DIR=true/)
          expect(content).to match(/chmod 0700 \/run\/gitlab\/sidekiq/)
          expect(content).to match(/chown git \/run\/gitlab\/sidekiq/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/sidekiq\'/)
          expect(content).to match(/\-C \/opt\/gitlab\/embedded\/service\/.*\/config\/sidekiq_queues.yml/)
          expect(content).to match(/\-t 4/)
          expect(content).to match(/\-c 25/)
        }
    end

    it_behaves_like "enabled runit service", "sidekiq", "root", "root", "git", "git"
  end

  context 'with blank runtime_dir' do
    before do
      allow(Gitlab).to receive(:[]).with('runtime_dir').and_return(nil)
    end

    it 'does not render the DO_NOT_CLEAN_METRICS_DIR var' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content { |content|
        expect(content).not_to match(/export DO_NOT_CLEAN_METRICS_DIR=true/)
        expect(content).to match(/\-c 25/) # to ensure something got rendered
      }
    end
  end

  context 'with specified values' do
    before do
      stub_gitlab_rb(
        sidekiq: {
          shutdown_timeout: 8, concurrency: 35
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end
    it 'correctly renders out the sidekiq service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-t 8/)
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-c 35/)
    end

    it_behaves_like "enabled runit service", "sidekiq", "root", "root", "foo", "bar"
  end
end
