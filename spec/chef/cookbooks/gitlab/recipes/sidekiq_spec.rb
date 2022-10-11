require 'chef_helper'

RSpec.describe 'gitlab::sidekiq' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(sidekiq_service runit_service),
      path: 'spec/chef/fixtures/fauxhai/ubuntu/16.04.json'
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
          expect(content).to match(/chmod 0700 \/run\/gitlab\/sidekiq/)
          expect(content).to match(/chown git \/run\/gitlab\/sidekiq/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/sidekiq\'/)
          expect(content).to match(%r{bin/sidekiq-cluster})
          expect(content).to match(/-m 50/) # max_concurrency
          expect(content).to match(/--timeout 25/) # shutdown timeout
          expect(content).to match(/default,mailers/) # default queues
        }
    end

    it_behaves_like "enabled runit service", "sidekiq", "root", "root"
  end

  context 'with custom routing_rules' do
    before do
      stub_gitlab_rb(
        sidekiq: { routing_rules: [
          ['worker_name=AuthorizedProjectsWorker', 'urgent'],
          ['worker_name=SomeUrgentWorker', 'urgent'],
          ['resource_boundary=cpu', 'cpu_bound'],
          ['attribute=mailers', 'mailers']
        ] }
      )
    end

    it 'renders sidekiq service file with unique queues from routing_rules + mailers and deduplicate mailers queue' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run")
                            .with_content { |content|
                              puts content
                              expect(content).to match(/"urgent,cpu_bound,mailers"/)
                            }
    end

    describe 'when user specified queue_groups' do
      before do
        stub_gitlab_rb(
          sidekiq: { queue_groups: ['default,mailers,foo,bar'] }
        )
      end

      it 'renders sidekiq service file with user specified queue_groups regardless of routing rules' do
        expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run")
                              .with_content { |content|
                                expect(content).to match(/"default,mailers,foo,bar"/)
                              }
      end
    end
  end

  describe 'log_format' do
    context 'by default' do
      it 'does not pass timestamp flag to svlogd' do
        expect(chef_run).not_to render_file("/opt/gitlab/sv/sidekiq/log/run").with_content(/-tt/)
      end
    end

    context 'when user specifies text log format' do
      before do
        stub_gitlab_rb(
          sidekiq: { log_format: 'text' }
        )
      end

      it 'passes timestamp flag to svlogd' do
        expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/log/run").with_content(/-tt/)
      end
    end
  end

  include_examples "consul service discovery", "sidekiq", "sidekiq"
end
