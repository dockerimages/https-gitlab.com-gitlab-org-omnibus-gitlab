require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'sidekiq settings' do
    describe 'log_format' do
      context 'with default values' do
        it 'renders gitlab.yml with sidekiq log format set to json' do
          expect(gitlab_yml[:production][:sidekiq][:log_format]).to eq('json')
        end
      end

      context 'with user specified value' do
        before do
          stub_gitlab_rb(
            sidekiq: {
              log_format: 'text'
            }
          )
        end

        it 'renders gitlab.yml with user specified value for sidekiq log format' do
          expect(gitlab_yml[:production][:sidekiq][:log_format]).to eq('text')
        end
      end
    end

    describe 'routing_rules' do
      context 'with default values' do
        it 'renders gitlab.yml without routing_rules' do
          expect(gitlab_yml[:production][:sidekiq]).not_to include(:routing_rules)
        end
      end

      context 'with an empty array' do
        before do
          stub_gitlab_rb(
            sidekiq: {
              routing_rules: []
            }
          )
        end

        it 'renders gitlab.yml without routing_rules' do
          expect(gitlab_yml[:production][:sidekiq]).not_to include(:routing_rules)
        end
      end

      context 'with a valid routing rules list' do
        before do
          stub_gitlab_rb(
            sidekiq: {
              routing_rules: [
                ["resource_boundary=cpu", "cpu_boundary"],
                ["feature_category=pages", nil],
                ["feature_category=search", ''],
                ["feature_category=memory|resource_boundary=memory", ''],
                ["*", "default"]
              ]
            }
          )
        end

        it 'renders gitlab.yml with user specified value for sidekiq routing rules' do
          expect(gitlab_yml[:production][:sidekiq][:routing_rules]).to eq(
            [
              ["resource_boundary=cpu", "cpu_boundary"],
              ["feature_category=pages", nil],
              ["feature_category=search", ""],
              ["feature_category=memory|resource_boundary=memory", ""],
              ["*", "default"]
            ]
          )
        end
      end

      describe 'routing_rules relationship with queue_groups' do
        using RSpec::Parameterized::TableSyntax

        let(:user_specified_routing_rules) do
          [
            ["resource_boundary=cpu", "cpu_boundary"],
            ["feature_category=pages", nil],
            ["feature_category=search", ''],
            ["feature_category=memory|resource_boundary=memory", ''],
            ["*", "default"]
          ]
        end

        # rubocop: disable  Lint/BinaryOperatorWithIdenticalOperands
        where(:routing_rules, :queue_groups, :resulting_routing_rules) do
          nil                                | nil               | nil
          nil                                | ['*'] * 4         | nil
          nil                                | ['foo', '*', '*'] | [['*', nil]]
          nil                                | ['foo'] * 4       | [['*', nil]]
          ref(:user_specified_routing_rules) | nil               | ref(:user_specified_routing_rules)
          ref(:user_specified_routing_rules) | ['*'] * 4         | ref(:user_specified_routing_rules)
          ref(:user_specified_routing_rules) | ['foo', '*', '*'] | ref(:user_specified_routing_rules)
          ref(:user_specified_routing_rules) | ['foo'] * 4       | ref(:user_specified_routing_rules)
        end
        # rubocop: enable  Lint/BinaryOperatorWithIdenticalOperands

        with_them do
          before do
            stub_gitlab_rb(
              sidekiq: {
                routing_rules: routing_rules,
                queue_groups: queue_groups
              }
            )
          end

          it 'renders gitlab.yml based on resulting_routing_rules' do
            if resulting_routing_rules.nil?
              expect(gitlab_yml[:production][:sidekiq]).not_to include(:routing_rules)
            else
              expect(gitlab_yml[:production][:sidekiq][:routing_rules]).to eq(resulting_routing_rules)
            end
          end
        end
      end
    end
  end
end
