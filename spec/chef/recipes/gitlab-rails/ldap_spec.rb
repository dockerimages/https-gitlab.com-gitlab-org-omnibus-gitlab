require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'LDAP server configuration' do
    context 'with default values' do
      it 'renders gitlab.yml without LDAP settings' do
        expect(generated_yml_content[:production][:ldap]).to be nil
      end
    end

    context 'with user specified values' do
      context 'using new syntax for LDAP servers' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              ldap_enabled: true,
              prevent_ldap_sign_in: false,
              ldap_sync_time: 20,
              ldap_servers: {
                main: {
                  label: 'LDAP Primary',
                  host: 'primary.ldap',
                  port: 389,
                  uid: 'uid',
                  encryption: 'plain',
                  password: 's3cr3t',
                  base: 'dc=example,dc=com',
                  user_filter: ''
                },
                secondary: {
                  label: 'LDAP Secondary',
                  host: 'secondary.ldap',
                  port: 389,
                  uid: 'uid',
                  encryption: 'plain',
                  bind_dn: 'dc=example,dc=com',
                  password: 's3cr3t',
                  smartcard_auth: 'required',
                  base: '',
                  user_filter: '',
                }
              }
            })
        end

        it 'renders gitlab.yml with user specified values' do
          expected_output = {
            enabled: true,
            prevent_ldap_sign_in: false,
            sync_time: 20,
            servers: {
              main: {
                label: 'LDAP Primary',
                host: 'primary.ldap',
                port: 389,
                uid: 'uid',
                encryption: 'plain',
                password: 's3cr3t',
                base: 'dc=example,dc=com',
                user_filter: ''
              },
              secondary: {
                label: 'LDAP Secondary',
                host: 'secondary.ldap',
                port: 389,
                uid: 'uid',
                encryption: 'plain',
                bind_dn: 'dc=example,dc=com',
                password: 's3cr3t',
                smartcard_auth: 'required',
                base: '',
                user_filter: '',
              }
            }
          }

          expect(generated_yml_content[:production][:ldap]).to eq(expected_output)
        end
      end

      context 'when using old syntax with single LDAP server' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              ldap_enabled: true,
              prevent_ldap_sign_in: false,
              ldap_host: 'primary.ldap',
              ldap_port: 389,
              ldap_uid: 'uid',
              ldap_password: 's3cr3t',
              ldap_base: 'dc=example,dc=com',
              ldap_user_filter: '',
              ldap_method: 'plain',
              ldap_bind_dn: 'foobar',
              ldap_active_directory: 'asdf',
              ldap_allow_username_or_email_login: false,
              ldap_lowercase_usernames: true,
              ldap_group_base: 'dc-example.com',
              ldap_admin_group: 'foo',
              ldap_sync_ssh_keys: true,
              ldap_sync_time: 10
            }
          )
        end

        it 'renders gitlab.yml with user specified values' do
          expected_output = {
            enabled: true,
            prevent_ldap_sign_in: false,
            sync_time: 10,
            host: 'primary.ldap',
            port: 389,
            uid: 'uid',
            password: 's3cr3t',
            base: 'dc=example,dc=com',
            user_filter: '',
            method: 'plain',
            bind_dn: 'foobar',
            active_directory: 'asdf',
            allow_username_or_email_login: false,
            lowercase_usernames: true,
            group_base: 'dc-example.com',
            admin_group: 'foo',
            sync_ssh_keys: 'true',
          }

          expect(generated_yml_content[:production][:ldap]).to eq(expected_output)
        end
      end
    end
  end
end
