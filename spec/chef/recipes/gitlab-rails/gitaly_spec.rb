require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'Gitaly settings' do
    describe 'Gitaly token' do
      context 'with default values' do
        it 'renders gitlab.yml without Gitaly token set' do
          expect(generated_yml_content[:production][:gitaly][:token]).to eq("")
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              gitaly_token: 'token123456'
            }
          )
        end

        it 'renders gitlab.yml with user specified values' do
          expect(generated_yml_content[:production][:gitaly][:token]).to eq('token123456')
        end
      end
    end
  end
end
