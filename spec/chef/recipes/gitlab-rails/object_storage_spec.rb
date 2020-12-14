require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'object storage settings' do
    include_context 'object storage config'
    let(:aws_connection_data) { JSON.parse(aws_connection_hash.to_json, symbolize_names: true) }
    let(:aws_storage_options) { JSON.parse(aws_storage_options_hash.to_json, symbolize_names: true) }

    describe 'consolidated object storage settings' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            object_store: {
              enabled: true,
              connection: aws_connection_hash,
              storage_options: aws_storage_options_hash,
              objects: object_config
            }
          }
        )
      end

      it 'generates gitlab.yml properly with specified values' do
        config = generated_yml_content[:production]

        expect(config[:object_store][:enabled]).to be true
        expect(config[:object_store][:connection]).to eq(aws_connection_data)
        expect(config[:object_store][:storage_options]).to eq(aws_storage_options)
        expect(config[:object_store][:objects]).to eq(object_config)
      end
    end

    describe 'individual object storage settings' do
      # Parameters are:
      # 1. Component name
      # 2. Default settings deviating from general pattern
      # 3. Whether Workhorse acceleration is in place - decides whether to
      #    include background_upload, direct_upload, proxy_download etc.
      include_examples 'renders object storage settings in gitlab.yml', 'artifacts'
      include_examples 'renders object storage settings in gitlab.yml', 'uploads'
      include_examples 'renders object storage settings in gitlab.yml', 'external_diffs', { remote_directory: 'external-diffs' }
      include_examples 'renders object storage settings in gitlab.yml', 'lfs', { remote_directory: 'lfs-objects' }
      include_examples 'renders object storage settings in gitlab.yml', 'packages'
      include_examples 'renders object storage settings in gitlab.yml', 'dependency_proxy'
      include_examples 'renders object storage settings in gitlab.yml', 'terraform_state', { remote_directory: 'terraform' }, false
      include_examples 'renders object storage settings in gitlab.yml', 'pages', {}, false
    end
  end
end
