require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'repositories storages settings' do
    context 'with default values' do
      it 'renders gitlab.yml with default settings' do
        expect(generated_yml_content[:production][:repositories][:storages]).to eq(
          default: {
            gitaly_address: 'unix:/var/opt/gitlab/gitaly/gitaly.socket',
            path: '/var/opt/gitlab/git-data/repositories'
          }
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          git_data_dirs: {
            second_storage: {
              path: '/tmp/foobar',
              gitaly_address: 'unix:/var/gitaly.socket'
            }
          }
        )
      end

      it 'renders gitlab.yml with specified settings' do
        expect(generated_yml_content[:production][:repositories][:storages]).to eq(
          second_storage: {
            gitaly_address: 'unix:/var/gitaly.socket',
            path: '/tmp/foobar/repositories'
          }
        )
      end

      context 'when path is not provided for a storage' do
        before do
          stub_gitlab_rb(
            git_data_dirs: {
              default: {
                gitaly_address: 'unix:/var/gitaly.socket'
              }
            }
          )
        end

        it 'sets the default path' do
          expect(generated_yml_content[:production][:repositories][:storages]).to eq(
            default: {
              gitaly_address: 'unix:/var/gitaly.socket',
              path: '/var/opt/gitlab/git-data/repositories'
            }
          )
        end
      end
    end
  end
end
