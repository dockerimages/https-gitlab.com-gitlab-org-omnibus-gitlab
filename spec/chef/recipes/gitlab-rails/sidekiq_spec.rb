require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'sidekiq settings' do
    describe 'log format' do
      context 'with default values' do
        it 'renders gitlab.yml with default values' do
          expect(generated_yml_content[:production][:sidekiq][:log_format]).to eq('json')
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            sidekiq: {
              log_format: 'text'
            }
          )
        end

        it 'renders gitlab.yml with user specified values' do
          expect(generated_yml_content[:production][:sidekiq][:log_format]).to eq('text')
        end
      end
    end
  end
end
