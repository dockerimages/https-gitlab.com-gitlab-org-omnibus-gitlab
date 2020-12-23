require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Geo settings' do
    context 'with default values' do
      it 'renders gitlab.yml with default values' do
        expect(generated_yml_content[:production][:geo]).to eq(
          node_name: nil,
          registry_replication: {
            enabled: nil,
            primary_api_url: nil
          }
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            geo_node_name: 'foobar',
            geo_registry_replication_enabled: true,
            geo_registry_replication_primary_api_url: 'https://example.com'
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(generated_yml_content[:production][:geo]).to eq(
          node_name: 'foobar',
          registry_replication: {
            enabled: true,
            primary_api_url: 'https://example.com'
          }
        )
      end
    end
  end
end
