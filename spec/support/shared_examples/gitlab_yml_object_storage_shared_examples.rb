shared_examples 'renders object storage settings in gitlab.yml' do |component, component_default = {}, workhorse_accelerated = true|
  include_context 'gitlab-rails'
  include_context 'object storage config'

  let(:aws_connection_data) { JSON.parse(aws_connection_hash.to_json, symbolize_names: true) }
  let(:aws_storage_options) { JSON.parse(aws_storage_options_hash.to_json, symbolize_names: true) }
  let!(:default_values) do
  end

  describe "for #{component}" do
    context 'with default values' do
      it 'renders gitlab.yml with object storage disabled and other default values' do
        default_values = {
          enabled: false,
          remote_directory: component,
          connection: {}
        }

        if workhorse_accelerated
          default_values.merge!(
            direct_upload: false,
            background_upload: true,
            proxy_download: false
          )
        end

        default_values.merge!(component_default)

        config = generated_yml_content[:production][component.to_sym][:object_store]
        expect(config).to eq(default_values)
      end
    end

    context 'with user specified values' do
      before do
        gitlab_rails_config = {
          "#{component}_object_store_enabled" => true,
          "#{component}_object_store_remote_directory" => 'foobar',
          "#{component}_object_store_connection" => aws_connection_hash
        }

        if workhorse_accelerated
          gitlab_rails_config.merge!(
            "#{component}_object_store_direct_upload" => true,
            "#{component}_object_store_background_upload" => false,
            "#{component}_object_store_proxy_download" => true
          )
        end

        stub_gitlab_rb(
          gitlab_rails: gitlab_rails_config.transform_keys(&:to_sym)
        )
      end

      it 'renders gitlab.yml with user specified values' do
        config = generated_yml_content[:production][component.to_sym][:object_store]
        expect(config[:enabled]).to be true
        expect(config[:connection]).to eq(aws_connection_data)
        expect(config[:remote_directory]).to eq('foobar')

        if workhorse_accelerated
          expect(config[:direct_upload]).to be true
          expect(config[:background_upload]).to be false
          expect(config[:proxy_download]).to be true
        end
      end
    end
  end
end
