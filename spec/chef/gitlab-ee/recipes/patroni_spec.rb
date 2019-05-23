require 'chef_helper'

describe 'patroni' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:patroni_conf) { '/var/opt/gitlab/patroni/patroni.yml' }
  let(:patroni_conf_block) do
    <<-EOF
---
scope: pg-ha-cluster
name: fauxhai.local
restapi:
  listen: 0.0.0.0:8009
  connect_address: 10.0.0.2:8009
consul:
  host: 127.0.0.1:8500
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: 'on'
        wal_keep_segments: 8
        max_wal_senders: 5
        max_replication_slots: 5
        checkpoint_timeout: 30
  users:
    gitlab_superuser:
      password: gitlabsuperuser
      options:
      - superuser
    gitlab_replicator:
      password: replicator
      options:
      - replication
postgresql:
  data_dir: "/var/opt/gitlab/postgresql/data"
  config_dir: "/var/opt/gitlab/postgresql/data"
  bin_dir: "/opt/gitlab/embedded/bin/"
  listen: 0.0.0.0:5432
  parameters:
    hba_file: "/var/opt/gitlab/postgresql/data/pg_hba.conf"
  authentication:
    superuser:
      username: gitlab_superuser
      password: gitlabsuperuser
    replication:
      username: gitlab_replicator
      password: replicator
  connect_address: 10.0.0.2:5432
    EOF
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'disabled by default' do
    it 'includes the disable recipe' do
      expect(chef_run).to include_recipe('patroni::disable')
    end
  end

  describe 'patroni::disable' do
    it_behaves_like 'disabled runit service', 'patroni'
  end

  context 'when enabled' do
    before do
      stub_gitlab_rb(
        patroni: {
          enable: true,
          users: {
            superuser: {
              username: 'gitlab_superuser',
              password: 'fakepassword'
            }
          },
          private_ipaddress: '10.0.0.2'
        }
      )
      stub_command("/opt/gitlab/embedded/bin/sv status patroni && /opt/gitlab/embedded/bin/patronictl -c /var/opt/gitlab/patroni/patroni.yml list | grep fauxhai.local | grep running").and_return(true)
    end

    it 'includes the enable recipe' do
      expect(chef_run).to include_recipe('patroni::enable')
    end

    describe 'patroni::enable' do
      it_behaves_like 'enabled runit service', 'patroni', 'root', 'root', 'gitlab-psql', 'gitlab-psql'

      it 'creates the necessary directories' do
        expect(chef_run).to create_directory('/var/opt/gitlab/patroni')
      end

      it 'notifies the reload action' do
        config_json = chef_run.file(patroni_conf)
        expect(config_json).to notify('runit_service[patroni]').to(:reload).delayed
      end

      it 'disables the postgresql recipe' do
        expect(chef_run).to include_recipe('postgresql::disable')
      end

      it 'executes update bootstrap config' do
        allow_any_instance_of(PatroniHelper).to receive(:node_status).and_return('running')

        expect(chef_run).to run_execute('update bootstrap config')
      end

      it 'creates the superuser database user' do
        expect(chef_run).to create_postgresql_user('gitlab_superuser').with(
          options: %w(superuser),
          password: 'fakepassword'
        )
      end
    end

    context 'with default options' do
      before do
        stub_gitlab_rb(
          patroni: {
            enable: true,
            private_ipaddress: '10.0.0.2'
          }
        )
      end
      it 'creates default patroni conf' do
        expect(chef_run).to render_file(patroni_conf).with_content(patroni_conf_block)
      end
    end

    context 'with non-default options' do
      before do
        stub_gitlab_rb(
          patroni: {
            enable: true,
            config: {
              scope: 'fakeclustername'
            },
            private_ipaddress: '10.0.0.2'
          }
        )
      end

      it 'allows the user to specify cluster name' do
        expect(chef_run).to render_file(patroni_conf).with_content(/scope: fakeclustername/)
      end
    end
  end
end
