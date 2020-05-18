require 'chef_helper'
require 'yaml'

describe 'patroni cookbook' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  let(:chef_run) do
    ChefSpec::SoloRunner.new.converge('gitlab-ee::default')
  end

  let(:patroni_config) do
    {
      name: 'fauxhai.local',
      scope: 'gitlab-postgresql-ha',
      log: {
        level: 'INFO'
      },
      consul: {
        url: 'http://127.0.0.1:8500',
        service_check_interval: '10s',
        register_service: false,
        checks: [],
      },
      postgresql: {
        bin_dir: '/opt/gitlab/embedded/bin',
        data_dir: '/var/opt/gitlab/postgresql/data',
        config_dir: '/var/opt/gitlab/postgresql/data',
        listen: :'5432',
        connect_address: "#{Patroni.private_ipv4}:5432",
        use_unix_socket: true,
        parameters: {
          unix_socket_directories: '/var/opt/gitlab/postgresql'
        },
        authentication: {
          superuser: {
            username: 'gitlab-psql'
          },
          replication: {
            username: 'gitlab_replicator'
          },
        },
      },
      bootstrap: {
        dcs: {
          loop_wait: 10,
          ttl: 30,
          retry_timeout: 10,
          maximum_lag_on_failover: 1_048_576,
          max_timelines_history: 0,
          master_start_timeout: 300,
          postgresql: {
            use_pg_rewind: false,
            use_slots: true,
            parameters: {
              wal_level: 'replica',
              hot_standby: true,
              wal_keep_segments: 8,
              max_replication_slots: 5,
              max_wal_senders: 5,
              checkpoint_timeout: 30,
            },
          },
        },
        method: 'gitlab_ctl',
        gitlab_ctl: {
          command: '/opt/gitlab/bin/gitlab-ctl patroni bootstrap'
        },
        post_bootstrap: '/var/opt/gitlab/patroni/post-bootstrap'
      },
      restapi: {
        listen: :'8009',
        connect_address: "#{Patroni.private_ipv4}:8009",
      },
    }
  end

  let(:post_bootstrap) do
    <<~EOF
#!/bin/bash

# Parse connection
for pair in ${1}; do
  eval "_pg_${pair}"
done

PSQL="/opt/gitlab/embedded/bin/psql -h ${_pg_host} -p ${_pg_port} -U ${_pg_user}"

psql() {
  PGPASSFILE="${PGPASSFILE:-}" ${PSQL} -d ${1:-template1}
}

PGTGRM_EXTENSION='pg_trgm'
GITLAB_DATABASE_NAME='gitlabhq_production'
GITLAB_SQL_USER='gitlab'
GITLAB_SQL_USER_PASSWORD='md5'
GITLAB_PGBOUNCER_USER='pgbouncer'
GITLAB_PGBOUNCER_PASSWORD='md5'
GITLAB_AUTH_FUNCTION='    CREATE OR REPLACE FUNCTION public.pg_shadow_lookup(in i_username text, out username text, out password text) RETURNS record AS $$
    BEGIN
        SELECT usename, passwd FROM pg_catalog.pg_shadow
        WHERE usename = i_username INTO username, password;
        RETURN;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    REVOKE ALL ON FUNCTION public.pg_shadow_lookup(text) FROM public, pgbouncer;
    GRANT EXECUTE ON FUNCTION public.pg_shadow_lookup(text) TO pgbouncer;
'

printf 'Creating %s user\\n' ${GITLAB_SQL_USER}
psql <<-SQL
CREATE USER "${GITLAB_SQL_USER}" WITH LOGIN PASSWORD '${GITLAB_SQL_USER_PASSWORD}';
SQL

printf 'Creating %s user\\n' ${GITLAB_PGBOUNCER_USER}
psql <<-SQL
CREATE USER "${GITLAB_PGBOUNCER_USER}" WITH LOGIN PASSWORD '${GITLAB_PGBOUNCER_PASSWORD}';
SQL

printf 'Creating %s database\\n' ${GITLAB_DATABASE_NAME}
psql <<-SQL
CREATE DATABASE "${GITLAB_DATABASE_NAME}" WITH OWNER "${GITLAB_SQL_USER}";
SQL

printf 'Creating %s extension\\n' ${PGTGRM_EXTENSION}
psql ${GITLAB_DATABASE_NAME} <<-SQL
CREATE EXTENSION IF NOT EXISTS "${PGTGRM_EXTENSION}";
SQL

[ -n "${GITLAB_AUTH_FUNCTION}" ] && psql ${GITLAB_DATABASE_NAME} < <( printf "${GITLAB_AUTH_FUNCTION}" )
    EOF
  end

  it 'should be disabled by default' do
    expect(chef_run).to include_recipe('patroni::disable')
  end

  context 'when repmgr is enabled' do
    before do
      stub_gitlab_rb(
        roles: %w(consul_role postgres_role)
      )
    end

    it 'should be disabled while repmgr is enabled' do
      expect(chef_run).to include_recipe('repmgr::enable')
      expect(chef_run).to include_recipe('patroni::disable')
    end
  end

  context 'when enabled with default config' do
    before do
      stub_gitlab_rb(
        roles: %w(consul_role postgres_role),
        patroni: {
          enable: true
        }
      )
      allow_any_instance_of(OmnibusHelper).to receive(:service_dir_enabled?).and_return(true)
      allow_any_instance_of(PgHelper).to receive(:bootstrapped?).and_return(false)
    end

    it 'should be enabled while repmgr is disabled' do
      expect(chef_run).to include_recipe('repmgr::disable')
      expect(chef_run).to include_recipe('patroni::enable')
      expect(chef_run).to include_recipe('postgresql::enable')
      expect(chef_run).to include_recipe('consul::enable')
    end

    it 'should enable patroni service and disable postgresql runit service' do
      expect(chef_run).to enable_runit_service('patroni')
      expect(chef_run).to disable_runit_service('postgresql')
    end

    it 'should skip standalone postgresql configuration' do
      expect(chef_run).to create_postgresql_config('gitlab')
      expect(chef_run.postgresql_config('gitlab')).not_to notify('execute[start postgresql]').to(:run)
      expect(chef_run).not_to run_execute('/opt/gitlab/embedded/bin/initdb -D /var/opt/gilab/postgresql/data -E UTF8')
      expect(chef_run).not_to run_execute('create gitlabhq_production database')
      expect(chef_run).not_to create_postgresql_user('gitlab')
      expect(chef_run).not_to create_postgresql_user('gitlab_replicator')
      expect(chef_run).not_to enable_postgresql_extension('pg_trgm')
      expect(chef_run).not_to run_execute(/(start|reload) postgresql/)
    end
  end

  context 'when enabled with specific config' do
    before do
      stub_gitlab_rb(
        roles: %w(consul_role postgres_role),
        patroni: {
          enable: true
        }
      )
    end

    it 'should create patroni configuration file' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/patroni.yaml').with_content { |content|
        expect(YAML.safe_load(content, permitted_classes: [Symbol], symbolize_names: true)).to eq(patroni_config)
      }
    end

    it 'should create patroni post-bootstrap script' do
      expect(chef_run).to render_file('/var/opt/gitlab/patroni/post-bootstrap').with_content { |content|
        expect(content).to eq(post_bootstrap)
      }
    end
  end
end
