require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Mattermost settings' do
    context 'with default values' do
      it 'renders gitlab.yml with mattermost disabled' do
        expect(gitlab_yml[:production][:mattermost]).to eq(
          enabled: false
        )
      end
    end

    context 'with user specified values' do
      context 'Mattermost running on same server' do
        before do
          stub_gitlab_rb(
            mattermost_external_url: 'http://mattermost.example.com'
          )
        end

        it 'renders gitlab.yml with mattermost host set properly' do
          expect(gitlab_yml[:production][:mattermost]).to eq(
            enabled: true,
            host: 'http://mattermost.example.com'
          )
        end
      end

      context 'Mattermost running on a different server' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              mattermost_enabled: true,
              mattermost_host: 'http://mattermost.example.com'
            }
          )
        end

        it 'renders gitlab.yml with mattermost host set properly' do
          expect(gitlab_yml[:production][:mattermost]).to eq(
            enabled: true,
            host: 'http://mattermost.example.com'
          )
        end
      end

      context 'when both mattermost_host and mattermost_external_url are set' do
        before do
          stub_gitlab_rb(
            mattermost_external_url: 'http://foobar.com',
            gitlab_rails: {
              mattermost_enabled: true,
              mattermost_host: 'http://mattermost.example.com'
            }
          )
        end

        it 'renders gitlab.yml with mattermost host set from mattermost_external_url' do
          expect(gitlab_yml[:production][:mattermost]).to eq(
            enabled: true,
            host: 'http://foobar.com'
          )
        end
      end
    end
  end
end
