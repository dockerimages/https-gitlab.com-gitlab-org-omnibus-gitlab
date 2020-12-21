require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'smartcard authentication settings' do
    context 'with default values' do
      it 'renders gitlab.yml with smartcard authentication disabled' do
        expect(generated_yml_content[:production][:smartcard]).to eq(
          enabled: false,
          ca_file: '/etc/gitlab/ssl/CA.pem',
          client_certificate_required_host: nil,
          client_certificate_required_port: 3444,
          required_for_git_access: false,
          san_extensions: false
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            smartcard_enabled: true,
            smartcard_ca_file: '/foobar/CA.pem',
            smartcard_client_certificate_required_host: 'smartcard.gitlab.example.com',
            smartcard_client_certificate_required_port: 123,
            smartcard_required_for_git_access: true,
            smartcard_san_extensions: true
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(generated_yml_content[:production][:smartcard]).to eq(
          enabled: true,
          ca_file: '/foobar/CA.pem',
          client_certificate_required_host: 'smartcard.gitlab.example.com',
          client_certificate_required_port: 123,
          required_for_git_access: true,
          san_extensions: true
        )
      end
    end
  end
end
