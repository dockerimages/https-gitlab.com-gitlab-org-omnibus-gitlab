require 'chef_helper'

RSpec.describe Gitaly do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'by default' do
    it 'provides settings needed for gitaly to run' do
      expect(chef_run.node['gitaly']['env']).to include(
        'HOME' => '/var/opt/gitlab',
        'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin'
      )
    end

    it 'does not include known settings in the environment' do
      expect(chef_run.node['gitaly']['env']).not_to include('GITALY_ENABLE')
    end
  end

  describe '.gitaly_address' do
    context 'by default' do
      it 'returns correct value' do
        chef_run

        expect(described_class.gitaly_address).to eq('unix:/var/opt/gitlab/gitaly/gitaly.socket')
      end
    end

    context 'when Gitaly listens over tcp' do
      before do
        stub_gitlab_rb(
          gitaly: {
            socket_path: '',
            listen_addr: '1.2.3.4'
          }
        )
      end

      it 'returns correct value' do
        chef_run

        expect(described_class.gitaly_address).to eq('tcp://1.2.3.4')
      end
    end

    context 'when Gitaly listens over tls' do
      before do
        stub_gitlab_rb(
          gitaly: {
            socket_path: '',
            listen_addr: '1.2.3.4',
            tls_listen_addr: '5.6.7.8'
          }
        )
      end

      it 'returns correct value' do
        chef_run

        expect(described_class.gitaly_address).to eq('tls://5.6.7.8')
      end
    end
  end

  describe '.parse_git_data_dirs' do
    context 'when git_data_dirs is not defined or empty' do
      it 'populates correct value for repositories_storages' do
        expected_config = {
          "default" => {
            "gitaly_address" => "unix:/var/opt/gitlab/gitaly/gitaly.socket",
            "path" => "/var/opt/gitlab/git-data/repositories"
          }
        }

        expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eq(expected_config)
      end
    end

    context 'using local Gitaly' do
      context 'with complete git_data_dirs' do
        before do
          stub_gitlab_rb(
            git_data_dirs:
            {
              'default' => {
                'path' => '/tmp/default/git-data'
              },
              'nfs1' => {
                'path' => '/mnt/nfs1'
              }
            }
          )
        end

        it 'populates correct value for repositories_storages' do
          expected_config = {
            "default" => {
              "gitaly_address" => "unix:/var/opt/gitlab/gitaly/gitaly.socket",
              "path" => "/tmp/default/git-data/repositories"
            },
            "nfs1" => {
              "gitaly_address" => "unix:/var/opt/gitlab/gitaly/gitaly.socket",
              "path" => "/mnt/nfs1/repositories"
            }
          }

          expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eq(expected_config)
        end
      end

      context 'when entry in git_data_dirs does not have path' do
        before do
          stub_gitlab_rb(
            git_data_dirs:
            {
              'default' => {
                'path' => '/tmp/default/git-data'
              },
              'nfs1' => {}
            }
          )
        end

        it 'populates correct value for repositories_storages' do
          expected_config = {
            "default" => {
              "gitaly_address" => "unix:/var/opt/gitlab/gitaly/gitaly.socket",
              "path" => "/tmp/default/git-data/repositories"
            },
            "nfs1" => {
              "gitaly_address" => "unix:/var/opt/gitlab/gitaly/gitaly.socket",
              "path" => "/var/opt/gitlab/git-data/repositories"
            }
          }

          expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eq(expected_config)
        end
      end
    end

    context 'when using external Gitaly' do
      context 'with complete git_data_dirs' do
        before do
          stub_gitlab_rb(
            git_data_dirs:
            {
              'default' => {
                'gitaly_address' => 'tcp://gitaly.internal:8075',
                'path' => '/tmp/git-data'
              }
            }
          )
        end

        it 'populates correct value for repositories_storages' do
          expected_config = {
            "default" => {
              "gitaly_address" => "tcp://gitaly.internal:8075",
              "path" => "/tmp/git-data/repositories"
            },
          }

          expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eq(expected_config)
        end
      end

      context 'when entry in git_data_dirs does not have path' do
        before do
          stub_gitlab_rb(
            git_data_dirs:
            {
              'default' => {
                'gitaly_address' => 'tcp://gitaly.internal:8075',
              }
            }
          )
        end

        it 'populates correct value for repositories_storages' do
          expected_config = {
            "default" => {
              "gitaly_address" => "tcp://gitaly.internal:8075",
              "path" => "/var/opt/gitlab/git-data/repositories"
            },
          }

          expect(chef_run.node['gitlab']['gitlab-rails']['repositories_storages']).to eq(expected_config)
        end
      end
    end
  end
end
