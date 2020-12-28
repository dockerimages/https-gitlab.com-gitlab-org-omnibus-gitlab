require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Consul settings' do
    context 'with default values' do
      it 'renders gitlab.yml without Consul settings' do
        expect(generated_yml_content[:production][:consul]).to be_nil
      end
    end

    context 'with user specified values' do
      context 'when built-in consul is enabled' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true
            }
          )
        end

        it 'renders gitlab.yml with default Consul settings' do
          expect(generated_yml_content[:production][:consul][:api_url]).to eq('http://localhost:8500')
        end
      end

      context 'when Consul is running on non-default location' do
        context 'set via client_addr and ports configuration' do
          before do
            stub_gitlab_rb(
              consul: {
                enable: true,
                configuration: {
                  client_addr: '10.0.0.1',
                  ports: {
                    http: 1234
                  }
                }
              }
            )
          end

          it 'renders gitlab.yml with specified Consul settings' do
            expect(generated_yml_content[:production][:consul][:api_url]).to eq('http://10.0.0.1:1234')
          end
        end

        context 'set via addresses and ports configuration' do
          before do
            stub_gitlab_rb(
              consul: {
                enable: true,
                configuration: {
                  client_addr: '10.0.0.1',
                  addresses: {
                    http: '10.0.1.2',
                  },
                  ports: {
                    http: 1234
                  }
                }
              }
            )
          end

          it 'renders gitlab.yml with specified Consul settings' do
            expect(generated_yml_content[:production][:consul][:api_url]).to eq('http://10.0.1.2:1234')
          end
        end

        context 'when http port is disabled via negative port number' do
          before do
            stub_gitlab_rb(
              consul: {
                enable: true,
                configuration: {
                  client_addr: '10.0.0.1',
                  addresses: {
                    https: '10.0.1.2',
                  },
                  ports: {
                    http: -1,
                    https: 1234
                  }
                }
              }
            )
          end

          it 'renders gitlab.yml with specified Consul settings' do
            expect(generated_yml_content[:production][:consul][:api_url]).to eq('https://10.0.1.2:1234')
          end
        end
      end
    end
  end
end
