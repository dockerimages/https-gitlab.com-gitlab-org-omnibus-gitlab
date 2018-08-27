require 'chef_helper'

describe 'gitlab::redis' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'by default' do
    it 'creates redis config with default values' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit normal 0 0 0/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit slave 256mb 64mb 60/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit pubsub 32mb 8mb 60/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 900 1/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 300 10/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 60 10000/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory 0/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-policy noeviction/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-samples 5/)
      expect(chef_run).not_to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^slaveof/)
    end
  end

  context 'with user specified values' do
    before do
      stub_gitlab_rb(
        redis: {
          client_output_buffer_limit_normal: "5 5 5",
          client_output_buffer_limit_slave: "512mb 128mb 120",
          client_output_buffer_limit_pubsub: "64mb 16mb 120",
          save: ["10 15000"],
          maxmemory: "32gb",
          maxmemory_policy: "allkeys-url",
          maxmemory_samples: 10
        }
      )
    end

    it 'creates redis config with custom values' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit normal 5 5 5/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit slave 512mb 128mb 120/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit pubsub 64mb 16mb 120/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 10 15000/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory 32gb/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-policy allkeys-url/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-samples 10/)
    end
  end

  context 'with snapshotting disabled' do
    before do
      stub_gitlab_rb(
        redis: {
          save: []
        }
      )
    end
    it 'creates redis config without save setting' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
      expect(chef_run).not_to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save/)
    end
  end

  context 'with snapshotting cleared' do
    before do
      stub_gitlab_rb(
        redis: {
          save: [""]
        }
      )
    end
    it 'creates redis config without save setting' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save ""/)
    end
  end

  context 'with a slave configured' do
    let(:redis_host) { '1.2.3.4' }
    let(:redis_port) { 6370 }
    let(:master_ip) { '10.0.0.0' }
    let(:master_port) { 6371 }

    before do
      stub_gitlab_rb(
        redis: {
          bind: redis_host,
          port: redis_port,
          master_ip: master_ip,
          master_port: master_port,
          master_password: 'password',
          master: false
        }
      )
    end

    it 'includes slaveof' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^slaveof #{master_ip} #{master_port}/)
    end
  end

  context 'with sysctl' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(sysctl)).converge('gitlab::default') }

    describe 'with unicorn disabled' do
      before do
        stub_gitlab_rb(
          unicorn: {
            enable: false
          }
        )
      end

      it 'does not create sysctl files' do
        # Unicorn also sets this value, so we need to disable Unicorn
        expect(chef_run).not_to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.core.somaxconn.conf')
        expect(chef_run).not_to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.ipv4.tcp_max_syn_backlog.conf')
      end
    end

    context 'with a TCP port' do
      let(:redis_host) { '1.2.3.4' }
      let(:redis_port) { 6370 }
      let(:defaults) do
        {
          unicorn: {
            enable: false
          },
          redis: {
            bind: redis_host,
            port: redis_port
          }
        }
      end

      describe 'default sysctl values' do
        before do
          stub_gitlab_rb(defaults)
        end

        it 'creates sysctl files' do
          expect(chef_run).to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.core.somaxconn.conf').with_content("1024")
          expect(chef_run).to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.ipv4.tcp_max_syn_backlog.conf').with_content("1024")
        end
      end

      describe 'custom sysctl values' do
        before do
          stub_gitlab_rb(defaults.merge(redis: { bind: redis_host, port: redis_port, somaxconn: 2048, tcp_max_syn_backlog: 2048 }))
        end

        it 'creates sysctl files' do
          expect(chef_run).to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.core.somaxconn.conf').with_content("2048")
          expect(chef_run).to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.ipv4.tcp_max_syn_backlog.conf').with_content("2048")
        end
      end

      describe 'disabled sysctl values' do
        before do
          stub_gitlab_rb(defaults.merge(redis: { bind: redis_host, port: redis_port, somaxconn: 0, tcp_max_syn_backlog: 0 }))
        end

        it 'creates sysctl files' do
          expect(chef_run).not_to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.core.somaxconn.conf')
          expect(chef_run).not_to render_file('/opt/gitlab/embedded/etc/90-omnibus-gitlab-net.ipv4.tcp_max_syn_backlog.conf')
        end
      end
    end
  end

  context 'in HA mode with Sentinels' do
    let(:redis_host) { '1.2.3.4' }
    let(:redis_port) { 6370 }
    let(:master_ip) { '10.0.0.0' }
    let(:master_port) { 6371 }

    before do
      stub_gitlab_rb(
        redis: {
          bind: redis_host,
          port: redis_port,
          ha: true,
          master_ip: master_ip,
          master_port: master_port,
          master_password: 'password',
          master: false
        }
      )
    end

    it 'omits slaveof' do
      expect(chef_run).not_to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^slaveof/)
    end
  end
end
