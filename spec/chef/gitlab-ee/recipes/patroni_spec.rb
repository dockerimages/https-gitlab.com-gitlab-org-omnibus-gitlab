require 'chef_helper'

describe 'patroni' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }
  let(:patroni_conf) { '/var/opt/gitlab/patroni/patroni.yml' }
  let(:patroni_conf_block) do
    <<-EOF
cluster=gitlab_cluster
node=1647392869
node_name=fauxhai.local
conninfo='host=fauxhai.local port=5432 user=gitlab_repmgr dbname=gitlab_repmgr sslmode=prefer sslcompression=0'

use_replication_slots=0
loglevel=INFO
logfacility=STDERR
event_notification_command='gitlab-ctl repmgr-event-handler  %n %e %s "%t" "%d"'

pg_bindir=/opt/gitlab/embedded/bin

service_start_command = /opt/gitlab/bin/gitlab-ctl start postgresql
service_stop_command = /opt/gitlab/bin/gitlab-ctl stop postgresql
service_restart_command = /opt/gitlab/bin/gitlab-ctl restart postgresql
service_reload_command = /opt/gitlab/bin/gitlab-ctl hup postgresql
failover = automatic
promote_command = /opt/gitlab/embedded/bin/repmgr standby promote -f /var/opt/gitlab/postgresql/repmgr.conf
follow_command = /opt/gitlab/embedded/bin/repmgr standby follow -f /var/opt/gitlab/postgresql/repmgr.conf
monitor_interval_secs=2
master_response_timeout=60
reconnect_attempts=6
reconnect_interval=10
retry_promote_interval_secs=300
witness_repl_nodes_sync_interval_secs=15
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
          log_directory: '/fake/log/patroni/'
        },
        postgresql: {
          super_user_password: 'fakepassword'
        }
      )
    end

    it 'includes the enable recipe' do
      expect(chef_run).to include_recipe('patroni::enable')
    end

    describe 'patroni::enable' do
      it_behaves_like 'enabled runit service', 'patroni', 'gitlab-psql', 'gitlab-psql', 'gitlab-psql', 'gitlab-psql'

      it 'creates the necessary directories' do
        expect(chef_run).to create_directory('/var/opt/gitlab/patroni')
        expect(chef_run).to create_directory('/fake/log/patroni')
      end

      it 'notifies the reload action' do
        config_json = chef_run.file(patroni_conf)
        expect(config_json).to notify('runit_service[patroni]').to(:reload).delayed
      end

      it 'disables the postgresql recipe' do
        expect(chef_run).to include_recipe('postgresql::disable')
      end

      it 'creates the superuser database user' do
        expect(chef_run).to create_postgresql_user('gitlab_superuser').with(
          options: %w(superuser),
          password: 'md5fakepassword'
        )
      end

    end

    context 'with default options' do
      before do
        stub_gitlab_rb(
          patroni: {
            enable: true
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
            node_name: 'fakeclustername',
            user: 'foo',
            group: 'bar',
          }
        )
      end

      it 'allows the user to specify cluster name' do
        expect(chef_run).to render_file(patroni_conf).with_content('"cluster_name":"fakenodename"')
      end

      it_behaves_like 'enabled runit service', 'patroni', 'foo', 'bar', 'foo', 'bar'
    end

  end

end
