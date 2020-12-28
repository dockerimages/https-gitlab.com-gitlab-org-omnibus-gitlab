require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Prometheus settings' do
    context 'with default values' do
      it 'renders gitlab.yml with built-in Prometheus details' do
        expect(generated_yml_content[:production][:prometheus]).to eq(
          enable: true,
          listen_address: 'localhost:9090',
          server_address: 'localhost:9090'
        )
      end
    end

    context 'with user specified values' do
      context 'when built-in Prometheus is running on non-default address' do
        before do
          stub_gitlab_rb(
            prometheus: {
              listen_address: '0.0.0.0:9191'
            }
          )
        end

        it 'renders gitlab.yml with correct values' do
          expect(generated_yml_content[:production][:prometheus]).to eq(
            enable: true,
            listen_address: '0.0.0.0:9191',
            server_address: '0.0.0.0:9191'
          )
        end
      end

      context 'when external Prometheus address is also specified' do
        before do
          stub_gitlab_rb(
            prometheus: {
              listen_address: '0.0.0.0:9191'
            },
            gitlab_rails: {
              prometheus_address: '1.1.1.1:2222'
            }
          )
        end

        it 'renders gitlab.yml with correct values' do
          expect(generated_yml_content[:production][:prometheus]).to eq(
            enable: true,
            listen_address: '1.1.1.1:2222',
            server_address: '1.1.1.1:2222'
          )
        end
      end

      context 'when built-in prometheus is disabled and no external Prometheus address is specified' do
        before do
          stub_gitlab_rb(
            prometheus: {
              enable: false
            }
          )
        end
        it 'renders gitlab.yml without Prometheus settingns' do
          expect(generated_yml_content[:production][:prometheus]).to be_nil
        end
      end
    end
  end
end
