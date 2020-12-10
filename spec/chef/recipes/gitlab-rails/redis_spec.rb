require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'redis settings' do
    let(:resque_yml_file) { '/var/opt/gitlab/gitlab-rails/etc/resque.yml' }
    let(:cable_yml_file) { '/var/opt/gitlab/gitlab-rails/etc/cable.yml' }
    let(:redis_instances) { %w(cache queues shared_state) }

    context 'using default configuration' do
      it 'creates resque.yml file with default redis settings' do
        expect(chef_run).to render_file(resque_yml_file).with_content { |content|
          yaml_data = YAML.safe_load(content, [], [], true, symbolize_names: true)
          expect(yaml_data[:production][:url]).to eq 'unix:/var/opt/gitlab/redis/redis.socket'
          expect(yaml_data[:production].keys).to eq([:url])
        }
      end

      it 'creates cable.yml file with default redis settings' do
        expect(chef_run).to render_file(cable_yml_file).with_content { |content|
          yaml_data = YAML.safe_load(content, [], [], true, symbolize_names: true)
          expect(yaml_data[:production][:url]).to eq 'unix:/var/opt/gitlab/redis/redis.socket'
          expect(yaml_data[:production].keys).to eq([:adapter, :url])
        }
      end

      it 'does not render the separate instance configurations' do
        redis_instances.each do |instance|
          expect(chef_run).not_to render_file("#{config_dir}redis.#{instance}.yml")
        end
      end

      it 'deletes the separate instance config files' do
        redis_instances.each do |instance|
          expect(chef_run).to delete_file("/opt/gitlab/embedded/service/gitlab-rails/config/redis.#{instance}.yml")
          expect(chef_run).to delete_file("/var/opt/gitlab/gitlab-rails/etc/redis.#{instance}.yml")
        end
      end
    end

    context 'using user specified configuration' do
      context 'with custom redis host, port, database, and password' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_host: 'redis.example.com',
              redis_port: 8888,
              redis_database: 2,
              redis_password: 'mypass',
              redis_enable_client: false
            }
          )
        end

        it 'creates resque.yml file with specified redis settings' do
          expect(chef_run).to render_file(resque_yml_file).with_content { |content|
            yaml_data = YAML.safe_load(content, [], [], true, symbolize_names: true)
            expect(yaml_data[:production][:url]).to eq 'redis://:mypass@redis.example.com:8888/2'
            expect(yaml_data[:production][:id]).to eq nil
            expect(yaml_data[:production].keys).to eq([:url, :id])
          }
        end
      end

      context 'with multiple instances specified' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              redis_cache_instance: "redis://:fakepass@fake.redis.cache.com:8888/2",
              redis_cache_sentinels: [
                { host: 'cache', port: '1234' },
                { host: 'cache', port: '3456' }
              ],
              redis_queues_instance: "redis://:fakepass@fake.redis.queues.com:8888/2",
              redis_queues_sentinels: [
                { host: 'queues', port: '1234' },
                { host: 'queues', port: '3456' }
              ],
              redis_shared_state_instance: "redis://:fakepass@fake.redis.shared_state.com:8888/2",
              redis_shared_state_sentinels: [
                { host: 'shared_state', port: '1234' },
                { host: 'shared_state', port: '3456' }
              ],
              redis_actioncable_instance: "redis://:fakepass@fake.redis.actioncable.com:8888/2",
              redis_actioncable_sentinels: [
                { host: 'actioncable', port: '1234' },
                { host: 'actioncable', port: '3456' }
              ]
            }
          )
        end

        # This test does not work due to
        # https://github.com/chefspec/chefspec/issues/858
        # In gitlab-rails recipe, we are also doing a deletion action for the
        # same file resources, and chefspec will pick them over the
        # templatesymlink#create action.
        #
        # Hence, it is commented out, and we are fallbacking to using the
        # templatesymlink matcher instead.
        #
        # it 'renders separate instance config files' do
        #   redis_instances.each do |instance|
        #     expect(chef_run).to render_file("/var/opt/gitlab/gitlab-rails/etc/redis.#{instance}.yml").with_content { |content|
        #       yaml_data = YAML.safe_load(content, [], [], true, symbolize_names: true)
        #       expect(yaml_data[:production][:url]).to eq "redis://:fakepass@fake.redis.#{instance}.com:8888/2"
        #       expect(yaml_data[:production][:sentinels]).to eq(
        #         [
        #           {
        #             'host' => instance,
        #             'port' => 1234
        #           },
        #           {
        #             'host' => instance,
        #             'port' => 3456
        #           }
        #         ]
        #       )
        #     }
        #   end
        # end

        it 'renders separate instance config files' do
          redis_instances.each do |instance|
            expect(chef_run).to create_templatesymlink("Create a redis.#{instance}.yml and create a symlink to Rails root").with_variables(
              redis_url: "redis://:fakepass@fake.redis.#{instance}.com:8888/2",
              redis_sentinels: [{ "host" => instance, "port" => "1234" }, { "host" => instance, "port" => "3456" }]
            )
            expect(chef_run).not_to delete_file("/var/opt/gitlab/gitlab-rails/etc/redis.#{instance}.yml")
          end
        end

        it 'still renders the resque.yml file with specified values' do
          expect(chef_run).to render_file(resque_yml_file).with_content { |content|
            yaml_data = YAML.safe_load(content, [], [], true, symbolize_names: true)
            expect(yaml_data[:production][:url]).to eq 'unix:/var/opt/gitlab/redis/redis.socket'
          }
        end

        it 'still renders the cable.yml file with specified values' do
          expect(chef_run).to render_file(cable_yml_file).with_content { |content|
            yaml_data = YAML.safe_load(content, [], [], true, symbolize_names: true)
            expect(yaml_data[:production][:url]).to eq 'redis://:fakepass@fake.redis.actioncable.com:8888/2'
          }
        end
      end
    end
  end
end
