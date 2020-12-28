require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Registry settings' do
    context 'with default values' do
      context 'when GitLab is under http' do
        it 'renders gitlab.yml without Registry settings' do
          expect(generated_yml_content[:production][:registry]).to be_nil
        end
      end

      context 'when GitLab is running under https and using LE integration' do
        before do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com'
          )
        end

        it 'renders gitlab.yml with default Registry settings' do
          expect(generated_yml_content[:production][:registry]).to eq(
            enabled: true,
            host: 'gitlab.example.com',
            port: 5050,
            api_url: 'http://localhost:5000',
            issuer: 'omnibus-gitlab-issuer',
            key: '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key',
            notification_secret: nil,
            path: '/var/opt/gitlab/gitlab-rails/shared/registry'
          )
        end
      end

      context 'with user specified values' do
        context 'when built-in registry URL is specified' do
          before do
            stub_gitlab_rb(
              registry_external_url: 'http://registry.example.com'
            )
          end

          it 'renders gitlab.yml with default Registry settings' do
            expect(generated_yml_content[:production][:registry]).to eq(
              enabled: true,
              host: 'registry.example.com',
              port: nil,
              api_url: 'http://localhost:5000',
              issuer: 'omnibus-gitlab-issuer',
              key: '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key',
              notification_secret: nil,
              path: '/var/opt/gitlab/gitlab-rails/shared/registry'
            )
          end
        end

        context 'when other values are specified via registry settings' do
          before do
            stub_gitlab_rb(
              registry_external_url: 'http://registry.example.com:1234',
              registry: {
                registry_http_addr: 'localhost:1111'
              }
            )
          end

          it 'renders gitlab.yml with correct registry settings' do
            expect(generated_yml_content[:production][:registry]).to eq(
              enabled: true,
              host: 'registry.example.com',
              port: 1234,
              api_url: 'http://localhost:1111',
              issuer: 'omnibus-gitlab-issuer',
              key: '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key',
              notification_secret: nil,
              path: '/var/opt/gitlab/gitlab-rails/shared/registry'
            )
          end
        end

        context 'with external Registry' do
          before do
            stub_gitlab_rb(
              registry_external_url: 'http://registry.example.com:1234',
              gitlab_rails: {
                registry_enabled: 'true',
                registry_key_path: '/fake/path',
                registry_host: 'registry.example.com',
                registry_port: 1234,
                registry_issuer: 'foobar',
                registry_notification_secret: 'qwerty',
                registry_path: '/tmp/registry'
              }
            )
          end

          it 'renders gitlab.yml with correct registry settings' do
            expect(generated_yml_content[:production][:registry]).to eq(
              enabled: true,
              host: 'registry.example.com',
              port: 1234,
              api_url: 'http://localhost:5000',
              issuer: 'foobar',
              key: '/fake/path',
              notification_secret: 'qwerty',
              path: '/tmp/registry'
            )
          end
        end
      end
    end
  end
end
