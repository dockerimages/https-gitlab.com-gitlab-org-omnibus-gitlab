require 'chef_helper'

def get_active_config_content(content)
  # Cleanup in-line comments
  content.gsub!(/\s*#.*/, '')
  # Cleanup empty lines
  content.gsub!(/^\s*$\n/, '')

  content
end

RSpec.shared_examples 'renders configuration file properly' do |name, path, expected_content|
  it "renders #{name} with correct values" do
    expect(chef_run).to render_file(path).with_content { |content|
      expect(get_active_config_content(content)).to eq(expected_output)
    }
  end
end

RSpec.describe 'postgresql::enable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service postgresql_config)).converge('gitlab::default') }
  let(:postgresql_data_dir) { '/var/opt/gitlab/postgresql/data' }
  let(:postgresql_ssl_cert) { File.join(postgresql_data_dir, 'server.crt') }
  let(:postgresql_ssl_key) { File.join(postgresql_data_dir, 'server.key') }
  let(:runtime_conf) { '/var/opt/gitlab/postgresql/data/runtime.conf' }
  let(:gitlab_psql_rc) do
    <<~EOF
      psql_user='gitlab-psql'
      psql_group='gitlab-psql'
      psql_host='/var/opt/gitlab/postgresql'
      psql_port='5432'
    EOF
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:version).and_return(PGVersion.new('12.4'))
    allow_any_instance_of(PgHelper).to receive(:running_version).and_return(PGVersion.new('12.4'))
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(PGVersion.new('12.4'))
  end

  it 'includes the postgresql::bin recipe' do
    expect(chef_run).to include_recipe('postgresql::bin')
  end

  describe 'users, groups, and directories' do
    context 'with default values' do
      it 'creates necessary directories with default user and group' do
        directories = [
          %w[/var/opt/gitlab/postgresql 0755],
          %w[/var/opt/gitlab/postgresql/data 0700],
          %w[/var/log/gitlab/postgresql 0700]
        ]

        directories.each do |dir, mode|
          expect(chef_run).to create_directory(dir).with(
            owner: 'gitlab-psql',
            mode: mode,
            recursive: true
          )
        end
      end

      it 'initializes DB in the default data directory as default user' do
        expect(chef_run).to run_execute('/opt/gitlab/embedded/bin/initdb -D /var/opt/gitlab/postgresql/data -E UTF8').with(
          user: 'gitlab-psql'
        )
      end

      it_behaves_like 'enabled runit service', 'postgresql', 'root', 'root', 'gitlab-psql', 'gitlab-psql'
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          postgresql: {
            username: 'foo',
            group: 'bar',
            dir: '/mypgdir',
            home: '/mypghomedir',
            data_dir: '/mypgdatadir',
            log_directory: '/mypglogdir'
          }
        )
      end

      it 'creates specified directories with specified user and group' do
        directories = [
          %w[/mypgdir 0755],
          %w[/mypgdatadir 0700],
          %w[/mypglogdir 0700]
        ]

        directories.each do |dir, mode|
          expect(chef_run).to create_directory(dir).with(
            owner: 'foo',
            mode: mode,
            recursive: true
          )
        end
      end

      it 'initializes DB in the specified data directory as specified user' do
        expect(chef_run).to run_execute('/opt/gitlab/embedded/bin/initdb -D /mypgdatadir -E UTF8').with(
          user: 'foo'
        )
      end

      it_behaves_like 'enabled runit service', 'postgresql', 'root', 'root', 'foo', 'bar'

      it 'symlinks "data" subdirectory of PG directory to specified data directory' do
        expect(chef_run).to create_link('/mypgdir/data').with(
          to: '/mypgdatadir'
        )
      end
    end
  end

  describe 'kernel parameters' do
    it 'includes the package::sysctl recipe' do
      expect(chef_run).to include_recipe('package::sysctl')
    end

    context 'with default values' do
      context 'on amd64 machine' do
        it 'creates sysctl files with correct values' do
          expect(chef_run).to create_gitlab_sysctl('kernel.shmmax').with_value(17179869184)
          expect(chef_run).to create_gitlab_sysctl('kernel.shmall').with_value(4194304)
          expect(chef_run).to create_gitlab_sysctl('kernel.sem').with_value("250 32000 32 262")
        end
      end

      # context 'on aarch64 machine' do
      #   before do
      #     let(:chef_run) do
      #       ChefSpec::SoloRunner.new(
      #         step_into: %w(runit_service postgresql_config)

      #       ).converge('gitlab::default')
      #     end
      #   end
      #   it 'creates sysctl files with correct values' do
      #     expect(chef_run).to create_gitlab_sysctl('kernel.shmmax').with_value(17179869184)
      #     expect(chef_run).to create_gitlab_sysctl('kernel.shmall').with_value(4194304)
      #   end
      # end

      # context 'on armv7 machine' do
      #   it 'creates sysctl files with correct values' do
      #     expect(chef_run).to create_gitlab_sysctl('kernel.shmmax').with_value(4294967295)
      #     expect(chef_run).to create_gitlab_sysctl('kernel.shmall').with_value(1048575)
      #   end
      # end
    end
  end

  describe 'SSL certificate and key' do
    context 'with defaut values' do
      it 'creates self-signed certificate and key' do
        expect(chef_run).to create_file(postgresql_ssl_cert).with(
          content: %r{-----BEGIN CERTIFICATE-----},
          user: 'gitlab-psql',
          group: 'gitlab-psql',
          mode: 0400
        )
        expect(chef_run).to create_file(postgresql_ssl_key).with(
          content: %r{-----BEGIN RSA PRIVATE KEY-----},
          user: 'gitlab-psql',
          group: 'gitlab-psql',
          mode: 0400
        )
      end
    end

    context 'with user specified values' do
      context 'with SSL turned off' do
        before do
          stub_gitlab_rb(
            postgresql: {
              ssl: 'off'
            }
          )
        end

        it 'do not create self-signed certificates' do
          expect(chef_run).not_to create_file(postgresql_ssl_cert)
          expect(chef_run).not_to create_file(postgresql_ssl_key)
        end
      end

      context 'with user specified values for username and group' do
        before do
          stub_gitlab_rb(
            postgresql: {
              username: 'foo',
              group: 'bar'
            }
          )
        end

        it 'creates self-signed certificate and key with specified ownership' do
          expect(chef_run).to create_file(postgresql_ssl_cert).with(
            content: %r{-----BEGIN CERTIFICATE-----},
            user: 'foo',
            group: 'bar',
            mode: 0400
          )
          expect(chef_run).to create_file(postgresql_ssl_key).with(
            content: %r{-----BEGIN RSA PRIVATE KEY-----},
            user: 'foo',
            group: 'bar',
            mode: 0400
          )
        end
      end

      context 'with names SSL certificate and key files specified' do
        before do
          stub_gitlab_rb(
            postgresql: {
              ssl_cert_file: 'certfile',
              ssl_key_file: 'keyfile'
            }
          )
        end

        it 'creates self-signed certificate and key with specified names' do
          cert_file = File.join(postgresql_data_dir, 'certfile')
          key_file = File.join(postgresql_data_dir, 'keyfile')

          expect(chef_run).to create_file(cert_file).with(
            content: %r{-----BEGIN CERTIFICATE-----},
            user: 'gitlab-psql',
            group: 'gitlab-psql',
            mode: 0400
          )
          expect(chef_run).to create_file(key_file).with(
            content: %r{-----BEGIN RSA PRIVATE KEY-----},
            user: 'gitlab-psql',
            group: 'gitlab-psql',
            mode: 0400
          )
        end
      end

      context 'with internal certificate and key content specified' do
        before do
          stub_gitlab_rb(
            postgresql: {
              internal_certificate: 'foobar',
              internal_key: 'asdfasdf'
            }
          )
        end

        it 'populates certificate and key files with specified content' do
          expect(chef_run).to create_file(postgresql_ssl_cert).with(
            content: 'foobar',
            user: 'gitlab-psql',
            group: 'gitlab-psql',
            mode: 0400
          )
          expect(chef_run).to create_file(postgresql_ssl_key).with(
            content: 'asdfasdf',
            user: 'gitlab-psql',
            group: 'gitlab-psql',
            mode: 0400
          )
        end
      end
    end
  end

  describe 'PostgreSQL configuration' do
    describe 'postgresql.conf' do
      context 'with default values' do
        let(:expected_output) do
          <<~EOF
            listen_addresses = ''
            port = 5432
            max_connections = 200
            unix_socket_directories = '/var/opt/gitlab/postgresql'
            ssl = on
            ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL:!SSLv3:!TLSv1'
            ssl_cert_file = 'server.crt'
            ssl_key_file = 'server.key'
            ssl_ca_file = '/opt/gitlab/embedded/ssl/certs/cacert.pem'
            shared_buffers = 256MB
            shared_preload_libraries = ''
            wal_level = minimal
            wal_log_hints = off
            wal_buffers = -1
            min_wal_size = 80MB
            max_wal_size = 1GB
            max_replication_slots = 0
            archive_mode = off
            max_wal_senders = 0
            hot_standby = off
            track_activity_query_size = 1024
            autovacuum_max_workers = 3
            autovacuum_freeze_max_age = 200000000
            max_locks_per_transaction = 128
            include 'runtime.conf'
          EOF
        end

        include_examples 'renders configuration file properly', 'PostgreSQL Configuration', '/var/opt/gitlab/postgresql/data/postgresql.conf'
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            postgresql: {
              username: 'foo',
              group: 'bar',
              dir: '/mypgdir',
              home: '/mypghomedir',
              data_dir: '/mypgdatadir',
              log_directory: '/mypglogdir',
              listen_address: '1.2.3.4,2.3.4.5',
              port: 1234,
              max_connections: 500,
              ssl_ciphers: 'FOOBAR',
              ssl_crl_file: 'revoke.crl',
              shared_buffers: '500MB',
              shared_preload_libraries: 'pg_stat_statements',
              wal_level: 'replica',
              wal_log_hints: 'on',
              wal_buffers: 10,
              min_wal_size: '100MB',
              max_wal_size: '2GB',
              max_replication_slots: 10,
              dynamic_shared_memory_type: 'none',
              archive_mode: 'on',
              max_wal_senders: 10,
              hot_standby: 'on',
              logging_collector: 'on',
              track_activity_query_size: 2048,
              autovacuum_max_workers: 5,
              autovacuum_freeze_max_age: '400000000',
              max_locks_per_transaction: 256
            }
          )
        end

        let(:expected_output) do
          <<~EOF
            listen_addresses = '1.2.3.4,2.3.4.5'
            port = 1234
            max_connections = 500
            unix_socket_directories = '/mypgdir'
            ssl = on
            ssl_ciphers = 'FOOBAR'
            ssl_cert_file = 'server.crt'
            ssl_key_file = 'server.key'
            ssl_ca_file = '/opt/gitlab/embedded/ssl/certs/cacert.pem'
            ssl_crl_file = 'revoke.crl'
            shared_buffers = 500MB
            shared_preload_libraries = 'pg_stat_statements'
            wal_level = replica
            wal_log_hints = on
            wal_buffers = 10
            min_wal_size = 100MB
            max_wal_size = 2GB
            max_replication_slots = 10
            dynamic_shared_memory_type = none
            archive_mode = on
            max_wal_senders = 10
            hot_standby = on
            logging_collector = on
            track_activity_query_size = 2048
            autovacuum_max_workers = 5
            autovacuum_freeze_max_age = 400000000
            max_locks_per_transaction = 256
            include 'runtime.conf'
          EOF
        end

        include_examples 'renders configuration file properly', 'PostgreSQL Configuration', '/mypgdatadir/postgresql.conf'
      end
    end

    describe 'runtime.conf' do
      context 'with default values' do
        let(:expected_output) do
          <<~EOF
            work_mem = 16MB
            maintenance_work_mem = 16MB
            synchronous_commit = on
            synchronous_standby_names = ''
            min_wal_size = 80MB
            max_wal_size = 1GB
            checkpoint_timeout = 5min
            checkpoint_completion_target = 0.9
            checkpoint_warning = 30s
            log_directory = '/var/log/gitlab/postgresql'
            archive_command = ''
            archive_timeout = 0
            wal_keep_segments = 10
            max_standby_archive_delay = 30s
            max_standby_streaming_delay = 30s
            hot_standby_feedback = off
            random_page_cost = 2.0
            effective_cache_size = 512MB
            log_min_duration_statement = -1
            log_checkpoints = off
            log_line_prefix = ''
            log_temp_files = -1
            autovacuum = on
            log_autovacuum_min_duration = -1
            autovacuum_naptime = 1min
            autovacuum_vacuum_threshold = 50
            autovacuum_analyze_threshold = 50
            autovacuum_vacuum_scale_factor = 0.02
            autovacuum_analyze_scale_factor = 0.01
            autovacuum_vacuum_cost_delay = 20ms
            autovacuum_vacuum_cost_limit = -1
            default_statistics_target = 1000
            statement_timeout = 60000
            idle_in_transaction_session_timeout = 60000
            effective_io_concurrency = 1
            track_io_timing = 'off'
            max_worker_processes = 8
            max_parallel_workers_per_gather = 0
            deadlock_timeout = '5s'
            log_lock_waits = 1
            datestyle = 'iso, mdy'
            lc_messages = 'C'
            lc_monetary = 'C'
            lc_numeric = 'C'
            lc_time = 'C'
            default_text_search_config = 'pg_catalog.english'
          EOF
        end

        include_examples 'renders configuration file properly', 'PostgreSQL runtime Configuration', '/var/opt/gitlab/postgresql/data/runtime.conf'
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            postgresql: {
              work_mem: '32MB',
              maintenance_work_mem: '32MB',
              synchronous_commit: 'off',
              synchronous_standby_names: '*',
              min_wal_size: '100MB',
              max_wal_size: '2GB',
              checkpoint_timeout: '10min',
              checkpoint_completion_target: 0.8,
              checkpoint_warning: '40s',
              log_directory: '/var/pglog',
              archive_command: 'cd ..',
              archive_timeout: 10,
              wal_keep_segments: 20,
              max_standby_archive_delay: '40s',
              max_standby_streaming_delay: '40s',
              hot_standby_feedback: 'on',
              random_page_cost: 2.0,
              effective_cache_size: '1GB',
              log_min_duration_statement: 100,
              log_checkpoints: 'on',
              log_line_prefix: 'foobar',
              log_temp_files: 100,
              autovacuum: 'off',
              log_autovacuum_min_duration: 100,
              autovacuum_naptime: '5min',
              autovacuum_vacuum_threshold: 100,
              autovacuum_analyze_threshold: 100,
              autovacuum_vacuum_scale_factor: 0.5,
              autovacuum_analyze_scale_factor: 0.05,
              autovacuum_vacuum_cost_delay: '40ms',
              autovacuum_vacuum_cost_limit: 10,
              default_statistics_target: 2000,
              statement_timeout: 80000,
              idle_in_transaction_session_timeout: 80000,
              effective_io_concurrency: 3,
              track_io_timing: 'on',
              max_worker_processes: 6,
              max_parallel_workers_per_gather: 1,
              deadlock_timeout: '10s',
              log_lock_waits: 2
            }
          )
        end

        let(:expected_output) do
          <<~EOF
            work_mem = 32MB
            maintenance_work_mem = 32MB
            synchronous_commit = off
            synchronous_standby_names = '*'
            min_wal_size = 100MB
            max_wal_size = 2GB
            checkpoint_timeout = 10min
            checkpoint_completion_target = 0.8
            checkpoint_warning = 40s
            log_directory = '/var/pglog'
            archive_command = 'cd ..'
            archive_timeout = 10
            wal_keep_segments = 20
            max_standby_archive_delay = 40s
            max_standby_streaming_delay = 40s
            hot_standby_feedback = on
            random_page_cost = 2.0
            effective_cache_size = 1GB
            log_min_duration_statement = 100
            log_checkpoints = on
            log_line_prefix = 'foobar'
            log_temp_files = 100
            autovacuum = off
            log_autovacuum_min_duration = 100
            autovacuum_naptime = 5min
            autovacuum_vacuum_threshold = 100
            autovacuum_analyze_threshold = 100
            autovacuum_vacuum_scale_factor = 0.5
            autovacuum_analyze_scale_factor = 0.05
            autovacuum_vacuum_cost_delay = 40ms
            autovacuum_vacuum_cost_limit = 10
            default_statistics_target = 2000
            statement_timeout = 80000
            idle_in_transaction_session_timeout = 80000
            effective_io_concurrency = 3
            track_io_timing = 'on'
            max_worker_processes = 6
            max_parallel_workers_per_gather = 1
            deadlock_timeout = '10s'
            log_lock_waits = 2
            datestyle = 'iso, mdy'
            lc_messages = 'C'
            lc_monetary = 'C'
            lc_numeric = 'C'
            lc_time = 'C'
            default_text_search_config = 'pg_catalog.english'
          EOF
        end

        include_examples 'renders configuration file properly', 'PostgreSQL runtime Configuration', '/var/opt/gitlab/postgresql/data/runtime.conf'
      end
    end
  end
end
