require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'GitLab Application Settings' do
    describe 'Content Security Policy settings' do
      context 'with default values' do
        it 'renders gitlab.yml without content security policy' do
          expect(generated_yml_content[:production][:gitlab][:content_security_policy]).to be nil
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              content_security_policy: {
                enabled: true,
                report_only: true,
                directives: {
                  default_src: "'self'",
                  script_src: "'self' http://recaptcha.net",
                  worker_src: "'self'"
                }
              }
            }
          )
        end

        it 'renders gitlab.yml with user specified values' do
          expect(generated_yml_content[:production][:gitlab][:content_security_policy]).to eq(
            enabled: true,
            report_only: true,
            directives: {
              default_src: "'self'",
              script_src: "'self' http://recaptcha.net",
              worker_src: "'self'"
            }
          )
        end
      end
    end

    describe 'SMIME email settings' do
      context 'with default values' do
        it 'renders gitlab.yml with SMIME email settings disabled' do
          expect(generated_yml_content[:production][:gitlab][:email_smime]).to eq(
            enabled: false,
            cert_file: '/etc/gitlab/ssl/gitlab_smime.crt',
            key_file: '/etc/gitlab/ssl/gitlab_smime.key',
            ca_certs_file: nil
          )
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              gitlab_email_smime_enabled: true,
              gitlab_email_smime_key_file: '/etc/gitlab/ssl/custom_gitlab_smime.key',
              gitlab_email_smime_cert_file: '/etc/gitlab/ssl/custom_gitlab_smime.crt',
              gitlab_email_smime_ca_certs_file: '/etc/gitlab/ssl/custom_gitlab_smime_cas.crt'
            }
          )
        end

        it 'renders gitlab.yml with user specified values' do
          expect(generated_yml_content[:production][:gitlab][:email_smime]).to eq(
            enabled: true,
            cert_file: '/etc/gitlab/ssl/custom_gitlab_smime.crt',
            key_file: '/etc/gitlab/ssl/custom_gitlab_smime.key',
            ca_certs_file: '/etc/gitlab/ssl/custom_gitlab_smime_cas.crt'
          )
        end
      end
    end

    describe 'Seat link' do
      context 'with default values' do
        it 'renders gitlab.yml with seat link enabled' do
          expect(generated_yml_content[:production][:gitlab][:seat_link_enabled]).to be true
        end
      end

      context 'with user specified value' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              seat_link_enabled: false
            }
          )
        end

        it 'renders gitlab.yml with user specified value' do
          expect(generated_yml_content[:production][:gitlab][:seat_link_enabled]).to be false
        end
      end
    end
  end
end
