require 'chef_helper'

RSpec.describe 'gitaly::enable' do
  cached(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:config_path) { '/var/opt/gitlab/gitaly/config.toml' }
  let(:config_toml) { get_rendered_toml(chef_run, config_path) }
  let(:default_env_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'TZ' => ':/etc/localtime',
      'HOME' => '/var/opt/gitlab',
      'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin',
      'ICU_DATA' => '/opt/gitlab/embedded/share/icu/current',
      'PYTHONPATH' => '/opt/gitlab/embedded/lib/python3.9/site-packages',
      'WRAPPER_JSON_LOGGING' => 'true',
      "GITALY_PID_FILE" => '/var/opt/gitlab/gitaly/gitaly.pid',
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'by default' do
    it 'includes gitaly::enable recipe' do
      expect(chef_run).to include_recipe('gitaly::enable')
    end

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/gitaly').with(user: 'git', mode: '0700')
      expect(chef_run).to create_directory('/var/opt/gitlab/gitaly/run').with(user: 'git', mode: '0700')
      expect(chef_run).to create_directory('/var/log/gitlab/gitaly').with(user: 'git', mode: '0700')
    end

    it 'deletes the old internal sockets directory' do
      expect(chef_run).to delete_directory("/var/opt/gitlab/gitaly/internal_sockets")
    end

    it 'creates env directory with default variables' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitaly/env').with_variables(default_env_vars)
    end

    it 'populates gitaly config.toml with defaults' do
      expected_config = {
        "gitaly-ruby": {
          dir: "/opt/gitlab/embedded/service/gitaly-ruby"
        },
        "gitlab-shell": {
          dir: "/opt/gitlab/embedded/service/gitlab-shell"
        },
        auth: {},
        bin_dir: "/opt/gitlab/embedded/bin",
        daily_maintenance: {},
        git: {
          bin_path: "/opt/gitlab/embedded/bin/git",
          use_bundled_binaries: true
        },
        gitlab: {
          relative_url_root: "",
          url: "http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket"
        },
        hooks: {},
        logging: {
          dir: "/var/log/gitlab/gitaly",
          format: "json"
        },
        prometheus_listen_addr: "localhost:9236",
        runtime_dir: "/var/opt/gitlab/gitaly/run",
        socket_path: "/var/opt/gitlab/gitaly/gitaly.socket",
        storage: [
          {
            name: "default",
            path: "/var/opt/gitlab/git-data/repositories"
          }
        ]
      }

      expect(config_toml).to eq(expected_config)
    end

    it_behaves_like "enabled runit service", "gitaly", "root", "root"

    it 'renders the runit run script with defaults' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run')
        .with_content(%r{ulimit -n 15000})
    end

    it 'does not append timestamp in logs' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(/exec svlogd \/var\/log\/gitlab\/gitaly/)
    end

    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for Gitaly').with(
        version_file_path: '/var/opt/gitlab/gitaly/VERSION',
        version_check_cmd: "/opt/gitlab/embedded/bin/ruby -rdigest/sha2 -e 'puts %(sha256:) + Digest::SHA256.file(%(/opt/gitlab/embedded/bin/gitaly)).hexdigest'"
      )

      expect(chef_run.version_file('Create version file for Gitaly')).to notify('runit_service[gitaly]').to(:hup)
    end

    it 'creates a default RUBY_VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create Ruby version file for Gitaly').with(
        version_file_path: '/var/opt/gitlab/gitaly/RUBY_VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/ruby --version'
      )

      expect(chef_run.version_file('Create Ruby version file for Gitaly')).to notify('runit_service[gitaly]').to(:hup)
    end

    include_examples "consul service discovery", "gitaly", "gitaly"
  end

  context 'with user specified values' do
    # Because we start stubbing things, we can no longer use the existing cached result.
    # However, we are trying to use one cached result for as much as tests possible.
    cached(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

    let(:runtime_dir) { '/var/opt/gitlab/gitaly/user_defined/run' }
    let(:socket_path) { '/tmp/gitaly.socket' }
    let(:listen_addr) { 'localhost:7777' }
    let(:tls_listen_addr) { 'localhost:8888' }
    let(:certificate_path) { '/path/to/cert.pem' }
    let(:key_path) { '/path/to/key.pem' }
    let(:prometheus_listen_addr) { 'localhost:9000' }
    let(:log_directory) { '/tmp/foobar' }
    let(:logging_level) { 'warn' }
    let(:logging_format) { 'default' }
    let(:logging_sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project' }
    let(:logging_ruby_sentry_dsn) { 'https://my_key:my_secret@sentry.io/test_project-ruby' }
    let(:logging_sentry_environment) { 'production' }
    let(:prometheus_grpc_latency_buckets) { [0.001, 0.005, 0.025, 0.1, 0.5, 1.0, 10.0, 30.0, 60.0, 300.0, 1500.0] }
    let(:auth_token) { '123secret456' }
    let(:auth_transitioning) { true }
    let(:ruby_max_rss) { 1000000 }
    let(:graceful_restart_timeout) { '20m' }
    let(:ruby_graceful_restart_timeout) { '30m' }
    let(:ruby_restart_delay) { '10m' }
    let(:ruby_num_workers) { 5 }
    let(:open_files_ulimit) { 10000 }
    let(:gitlab_url) { 'http://localhost:3000' }
    let(:workhorse_addr) { 'localhost:4000' }
    let(:gitaly_custom_hooks_dir) { '/path/to/gitaly/custom/hooks' }
    let(:user) { 'user123' }
    let(:password) { 'password321' }
    let(:ca_file) { '/path/to/ca_file' }
    let(:ca_path) { '/path/to/ca_path' }
    let(:read_timeout) { 123 }
    let(:pack_objects_cache_enabled) { true }
    let(:pack_objects_cache_dir) { '/pack-objects-cache' }
    let(:pack_objects_cache_max_age) { '10m' }

    before do
      stub_gitlab_rb(
        gitaly: {
          env: {
            SAMPLE: 'VALUE'
          },
          socket_path: socket_path,
          runtime_dir: runtime_dir,
          listen_addr: listen_addr,
          tls_listen_addr: tls_listen_addr,
          certificate_path: certificate_path,
          key_path: key_path,
          prometheus_listen_addr: prometheus_listen_addr,
          log_directory: log_directory,
          logging_level: logging_level,
          logging_format: logging_format,
          logging_sentry_dsn: logging_sentry_dsn,
          logging_ruby_sentry_dsn: logging_ruby_sentry_dsn,
          logging_sentry_environment: logging_sentry_environment,
          prometheus_grpc_latency_buckets: prometheus_grpc_latency_buckets.to_s,
          auth_token: auth_token,
          auth_transitioning: auth_transitioning,
          graceful_restart_timeout: graceful_restart_timeout,
          ruby_max_rss: ruby_max_rss,
          ruby_graceful_restart_timeout: ruby_graceful_restart_timeout,
          ruby_restart_delay: ruby_restart_delay,
          ruby_num_workers: ruby_num_workers,
          open_files_ulimit: open_files_ulimit,
          pack_objects_cache_enabled: pack_objects_cache_enabled,
          pack_objects_cache_dir: pack_objects_cache_dir,
          pack_objects_cache_max_age: pack_objects_cache_max_age,
          custom_hooks_dir: gitaly_custom_hooks_dir,
          storage: [
            {
              'name' => 'default',
              'path' => '/tmp/path-1'
            },
            {
              'name' => 'nfs1',
              'path' => '/mnt/nfs1'
            }
          ]
        },
        gitlab_rails: {
          internal_api_url: gitlab_url
        },
        gitlab_shell: {
          http_settings: {
            read_timeout: read_timeout,
            user: user,
            password: password,
            ca_file: ca_file,
            ca_path: ca_path
          }
        },
        gitlab_workhorse: {
          listen_network: 'tcp',
          listen_addr: workhorse_addr,
        },
        user: {
          username: 'foo',
          group: 'bar',
          home: '/my/random/path'
        }
      )
    end

    it 'creates expected directories with correct permissions' do
      expect(chef_run).to create_directory('/var/opt/gitlab/gitaly').with(user: 'foo', mode: '0700')
      expect(chef_run).to create_directory(runtime_dir).with(user: 'foo', mode: '0700')
      expect(chef_run).to create_directory(log_directory).with(user: 'foo', mode: '0700')
    end

    it 'creates env directory with specified and computed variables along with default variables' do
      extra_vars = {
        'SAMPLE' => 'VALUE',
        'HOME' => '/my/random/path',
        'WRAPPER_JSON_LOGGING' => 'false',
      }

      expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitaly/env').with_variables(default_env_vars.merge(extra_vars))
    end

    it 'populates config file with user specified values for general settings' do
      expected_config = {
        socket_path: socket_path,
        runtime_dir: runtime_dir,
        graceful_restart_timeout: graceful_restart_timeout,
        listen_addr: listen_addr,
        prometheus_listen_addr: prometheus_listen_addr,
        tls_listen_addr: tls_listen_addr
      }

      expect(config_toml).to include(expected_config)
    end

    it 'populates config file with user specified values for tls settings' do
      expected_config = {
        tls: {
          certificate_path: certificate_path,
          key_path: key_path
        }
      }

      expect(config_toml).to include(expected_config)
    end

    describe 'storage settings' do
      let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

      context 'when specified via gitaly storages' do
        it 'populates config file with user specified values for storage settings' do
          expected_config = {
            storage: [
              {
                name: 'default',
                path: '/tmp/path-1'
              },
              {
                name: 'nfs1',
                path: '/mnt/nfs1'
              }
            ]
          }

          expect(config_toml).to include(expected_config)
        end
      end

      context 'when specified via git_data_dirs' do
        before do
          # Reset gitlab.rb
          allow(Gitlab).to receive(:[]).and_call_original
        end

        context 'using local gitaly' do
          before do
            stub_gitlab_rb(
              git_data_dirs:
              {
                'default' => {
                  'path' => '/tmp/default/git-data'
                },
                'nfs1' => {
                  'path' => '/mnt/nfs1'
                }
              }
            )
          end

          it 'computes Gitaly storages with user specified values and populates config file' do
            expected_config = {
              storage: [
                {
                  name: 'default',
                  path: '/tmp/default/git-data/repositories'
                },
                {
                  name: 'nfs1',
                  path: '/mnt/nfs1/repositories'
                }
              ]
            }

            expect(config_toml).to include(expected_config)
          end
        end

        context 'using external gitaly' do
          before do
            stub_gitlab_rb(
              git_data_dirs:
              {
                'default' => {
                  'gitaly_address' => 'tcp://gitaly.internal:8075',
                  'path' => '/tmp/gitaly'
                }
              }
            )
          end

          it 'computes Gitaly storages with user specified values and populates config file' do
            expected_config = {
              storage: [
                {
                  name: 'default',
                  path: '/tmp/gitaly/repositories'
                },
              ]
            }

            expect(config_toml).to include(expected_config)
          end
        end
      end
    end

    it 'populates config file with user specified values for logging settings' do
      expected_config = {
        logging: {
          level: logging_level,
          format: logging_format,
          sentry_dsn: logging_sentry_dsn,
          ruby_sentry_dsn: logging_ruby_sentry_dsn,
          sentry_environment: logging_sentry_environment,
          dir: log_directory,
        }
      }

      expect(config_toml).to include(expected_config)
    end

    it 'populates config file with user specified values for prometheus settings' do
      expected_config = {
        prometheus: {
          grpc_latency_buckets: prometheus_grpc_latency_buckets
        }
      }

      expect(config_toml).to include(expected_config)
    end

    it 'populates config file with user specified values for auth settings' do
      expected_config = {
        auth: {
          token: auth_token,
          transitioning: auth_transitioning
        }
      }

      expect(config_toml).to include(expected_config)
    end

    describe 'git settings' do
      let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }
      let(:git_catfile_cache_size) { 50 }
      let(:git_bin_path) { '/path/to/usr/bin/git' }

      before do
        stub_gitlab_rb(
          gitaly: {
            git_catfile_cache_size: git_catfile_cache_size,
            git_bin_path: git_bin_path,
            use_bundled_git: false,
          }
        )
      end

      it 'populates config file with user specified values' do
        expected_config = {
          git: {
            catfile_cache_size: git_catfile_cache_size,
            bin_path: git_bin_path,
          }
        }

        expect(config_toml).to include(expected_config)
      end

      describe 'gitconfig section' do
        let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

        context 'with default values' do
          it 'does not write a git.config section' do
            expect(config_toml[:git]).not_to include(:config)
          end
        end

        context 'with ignore_gitconfig turned on' do
          context 'with user specified omnibus gitconfig' do
            context 'with values same as default values' do
              before do
                stub_gitlab_rb(
                  gitaly: {
                    ignore_gitconfig: true
                  },
                  omnibus_gitconfig: {
                    system: {
                      pack: ["threads =1"],
                      receive: ["fsckObjects=true", "advertisePushOptions=true"],
                      repack: ["writeBitmaps= true"],
                    }
                  }
                )
              end

              it 'does not write a git.config section' do
                expect(config_toml[:git]).not_to include(:config)
              end
            end

            context 'with values same as default values but with weird spacing' do
              before do
                stub_gitlab_rb(
                  gitaly: {
                    ignore_gitconfig: true
                  },
                  omnibus_gitconfig: {
                    system: {
                      pack: ["threads =1"],
                      receive: ["fsckObjects=true", "advertisePushOptions   =    true"],
                      repack: ["writeBitmaps= true"],
                    }
                  }
                )
              end

              it 'does not write a git.config section' do
                expect(config_toml[:git]).not_to include(:config)
              end
            end

            context 'with mix of default and non-default values' do
              before do
                stub_gitlab_rb(
                  gitaly: {
                    ignore_gitconfig: true
                  },
                  omnibus_gitconfig: {
                    system: {
                      pack: ["threads =1"],
                      receive: ["fsckObjects=false", "advertisePushOptions=true"],
                      nondefault: ["foo=bar"]
                    }
                  }
                )
              end

              it 'writes a git.config section with only non-default values' do
                expected_config = {
                  bin_path: "/opt/gitlab/embedded/bin/git",
                  use_bundled_binaries: true,
                  ignore_gitconfig: true,
                  config: [
                    {
                      key: 'receive.fsckObjects',
                      value: 'false'
                    },
                    {
                      key: 'nondefault.foo',
                      value: 'bar'
                    },
                  ]
                }

                expect(config_toml[:git]).to eq(expected_config)
              end
            end
          end

          context 'with user specified gitaly gitconfig' do
            context 'set to empty array' do
              before do
                stub_gitlab_rb(
                  gitaly: {
                    ignore_gitconfig: true,
                    gitconfig: []
                  }
                )
              end

              it 'does not write a git.config section' do
                expect(config_toml[:git]).not_to include(:config)
              end
            end

            context 'along with omnibus gitconfig being a mix of default and non-default values' do
              before do
                stub_gitlab_rb(
                  gitaly: {
                    ignore_gitconfig: true,
                    gitconfig: [
                      {
                        key: "nondefault.foo",
                        value: "bar"
                      }
                    ]
                  },
                  omnibus_gitconfig: {
                    system: {
                      pack: ["threads =1"],
                      receive: ["fsckObjects=false"],
                      this: ["is=overridden"]
                    }
                  }
                )
              end

              it 'writes a git.config section with only values in gitaly gitconfig' do
                expected_config = [
                  {
                    key: 'nondefault.foo',
                    value: 'bar'
                  },
                ]

                expect(config_toml[:git][:config]).to match_array(expected_config)
              end
            end
          end
        end
      end
    end

    it 'populates config file with user specified values for gitaly-ruby settings' do
      expected_config = {
        "gitaly-ruby": {
          dir: "/opt/gitlab/embedded/service/gitaly-ruby",
          max_rss: ruby_max_rss,
          graceful_restart_timeout: ruby_graceful_restart_timeout,
          restart_delay: ruby_restart_delay,
          num_workers: ruby_num_workers
        }
      }

      expect(config_toml).to include(expected_config)
    end

    describe 'gitlab settings' do
      let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

      it 'populates config file with user specified values' do
        expected_config = {
          gitlab: {
            url: gitlab_url,
            'http-settings': {
              read_timeout: read_timeout,
              user: user,
              password: password,
              ca_file: ca_file,
              ca_path: ca_path
            }
          }
        }

        expect(config_toml).to include(expected_config)
      end

      context 'when GitLab available under relative URL' do
        before do
          # Reset gitlab.rb
          allow(Gitlab).to receive(:[]).and_call_original

          stub_gitlab_rb(
            external_url: 'http://example.com/gitlab'
          )
        end

        it 'populates config file with user specified values' do
          expected_config = {
            gitlab: {
              url: 'http+unix://%2Fvar%2Fopt%2Fgitlab%2Fgitlab-workhorse%2Fsockets%2Fsocket',
              relative_url_root: '/gitlab'
            }
          }

          expect(config_toml).to include(expected_config)
        end
      end

      context 'workhorse listening on non-default locations' do
        before do
          # Reset gitlab.rb
          allow(Gitlab).to receive(:[]).and_call_original
        end

        context 'over unix socket' do
          context 'with only a listen address set' do
            before do
              stub_gitlab_rb(
                gitlab_workhorse: {
                  listen_addr: '/fake/workhorse/socket'
                }
              )
            end

            it 'populates config file with user specified values' do
              expected_config = {
                gitlab: {
                  url: 'http+unix://%2Ffake%2Fworkhorse%2Fsocket',
                  relative_url_root: ''
                }
              }

              expect(config_toml).to include(expected_config)
            end
          end

          context 'with only a socket directory set' do
            before do
              stub_gitlab_rb(
                gitlab_workhorse: {
                  sockets_directory: '/fake/workhorse/sockets'
                }
              )
            end

            it 'populates config file with user specified values' do
              expected_config = {
                gitlab: {
                  url: 'http+unix://%2Ffake%2Fworkhorse%2Fsockets%2Fsocket',
                  relative_url_root: ''
                }
              }

              expect(config_toml).to include(expected_config)
            end
          end

          context 'with a listen_address and a sockets_directory set' do
            before do
              stub_gitlab_rb(
                gitlab_workhorse: {
                  listen_addr: '/sockets/in/the/wind',
                  sockets_directory: '/sockets/in/the'
                }
              )
            end

            it 'populates config file with user specified values' do
              expected_config = {
                gitlab: {
                  url: 'http+unix://%2Fsockets%2Fin%2Fthe%2Fwind',
                  relative_url_root: ''
                }
              }

              expect(config_toml).to include(expected_config)
            end
          end
        end

        context 'over tcp' do
          before do
            stub_gitlab_rb(
              external_url: 'http://example.com/gitlab',
              gitlab_workhorse: {
                listen_network: 'tcp',
                listen_addr: 'localhost:1234'
              }
            )
          end

          it 'populates config file with user specified values' do
            expected_config = {
              gitlab: {
                url: 'http://localhost:1234/gitlab'
              }
            }

            expect(config_toml).to include(expected_config)
          end
        end
      end
    end

    it 'populates config file with user specified values for hooks settings' do
      expected_config = {
        hooks: {
          custom_hooks_dir: gitaly_custom_hooks_dir
        }
      }

      expect(config_toml).to include(expected_config)
    end

    describe 'concurrency settings' do
      let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

      context 'when concurrency configuration is valid' do
        before do
          stub_gitlab_rb(
            gitaly: {
              concurrency: [
                {
                  rpc: '/gitaly.SmartHTTPService/PostReceivePack',
                  max_per_repo: 20
                },
                {
                  rpc: '/gitaly.SSHService/SSHUploadPack',
                  max_queue_wait: '10s',
                }
              ]
            }
          )
        end

        it 'populates config file with user specified values' do
          expected_config = {
            concurrency: [
              {
                rpc: '/gitaly.SmartHTTPService/PostReceivePack',
                max_per_repo: 20
              },
              {
                rpc: '/gitaly.SSHService/SSHUploadPack',
                max_queue_wait: '10s',
              }
            ]
          }

          expect(config_toml).to include(expected_config)
        end
      end

      context 'when concurrency configuration is empty' do
        before do
          stub_gitlab_rb(
            gitaly: {
              concurrency: []
            }
          )
        end

        it 'populates config file without concurrency settings' do
          expect(config_toml).not_to include(:concurrency)
        end
      end
    end

    describe 'rate limiting settings' do
      let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

      shared_examples 'without rate limiting configuration' do
        it 'populates config file without rate limiting settings' do
          expect(config_toml).not_to include(:rate_limiting)
        end
      end

      context 'when rate limiting configuration is valid' do
        before do
          stub_gitlab_rb(
            {
              gitaly: {
                rate_limiting: [
                  {
                    'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                    'interval' => '1s',
                    'burst' => 100
                  }, {
                    'rpc' => "/gitaly.SSHService/SSHUploadPack",
                    'interval' => '1s',
                    'burst' => 200,
                  }
                ]
              }
            }
          )
        end

        it 'populates config file with user specified values' do
          expected_config = {
            rate_limiting: [
              {
                rpc: "/gitaly.SmartHTTPService/PostReceivePack",
                interval: '1s',
                burst: 100
              }, {
                rpc: "/gitaly.SSHService/SSHUploadPack",
                interval: '1s',
                burst: 200,
              }
            ]
          }

          expect(config_toml).to include(expected_config)
        end
      end

      context 'when rate limiting configuration is empty' do
        before do
          stub_gitlab_rb(
            gitaly: {
              rate_limiting: []
            }
          )
        end

        include_examples 'without rate limiting configuration'
      end

      context 'when rate limiting configuration is incomplete' do
        context 'when interval is missing' do
          before do
            stub_gitlab_rb(
              {
                gitaly: {
                  rate_limiting: [{
                    'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                    'burst' => 100
                  }]
                }
              }
            )
          end

          include_examples 'without rate limiting configuration'
        end

        context 'when burst is missing' do
          before do
            stub_gitlab_rb(
              {
                gitaly: {
                  rate_limiting: [{
                    'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
                    'interval' => '1s',
                  }]
                }
              }
            )
          end

          include_examples 'without rate limiting configuration'
        end
      end
    end

    describe 'daily maintenance settings' do
      let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
      let(:daily_maintenance_start_hour) { 21 }
      let(:daily_maintenance_start_minute) { 9 }
      let(:daily_maintenance_duration) { '45m' }
      let(:daily_maintenance_storages) { ["default"] }

      context 'when explicitly disabled' do
        before do
          stub_gitlab_rb(
            gitaly: {
              daily_maintenance_disabled: 'true',
              daily_maintenance_start_hour: daily_maintenance_start_hour,
              daily_maintenance_start_minute: daily_maintenance_start_minute,
              daily_maintenance_duration: daily_maintenance_duration,
              daily_maintenance_storages: daily_maintenance_storages,
            }
          )
        end

        it 'populates config file without daily maintenance settings' do
          expected_config = {
            daily_maintenance: {
              disabled: true
            }
          }

          expect(config_toml).to include(expected_config)
        end
      end

      context 'when using single maintenance storage entry' do
        before do
          stub_gitlab_rb(
            gitaly: {
              daily_maintenance_start_hour: daily_maintenance_start_hour,
              daily_maintenance_start_minute: daily_maintenance_start_minute,
              daily_maintenance_duration: daily_maintenance_duration,
              daily_maintenance_storages: daily_maintenance_storages,
            }
          )
        end

        it 'populates config file with user specified values' do
          expected_config = {
            daily_maintenance: {
              start_hour: daily_maintenance_start_hour,
              start_minute: daily_maintenance_start_minute,
              duration: daily_maintenance_duration,
              storages: daily_maintenance_storages,
            }
          }

          expect(config_toml).to include(expected_config)
        end
      end

      context 'when using multiple maintenance storage entries' do
        before do
          stub_gitlab_rb(
            gitaly: {
              daily_maintenance_start_hour: daily_maintenance_start_hour,
              daily_maintenance_start_minute: daily_maintenance_start_minute,
              daily_maintenance_duration: daily_maintenance_duration,
              daily_maintenance_storages: %w[storage0 storage1 storage2]
            }
          )
        end

        it 'populates config file with user specified values' do
          expected_config = {
            daily_maintenance: {
              start_hour: daily_maintenance_start_hour,
              start_minute: daily_maintenance_start_minute,
              duration: daily_maintenance_duration,
              storages: %w[storage0 storage1 storage2]
            }
          }

          expect(config_toml).to include(expected_config)
        end
      end
    end

    describe 'cgroup settings' do
      let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

      let(:mountpoint) { '/sys/fs/cgroup' }
      let(:hierarchy_root) { 'gitaly' }
      let(:memory_bytes) { 2097152 }
      let(:cpu_shares) { 512 }
      let(:count) { 100 }

      context 'using pre-15.0 cgroup settings' do
        before do
          stub_gitlab_rb(
            gitaly: {
              cgroups_mountpoint: mountpoint,
              cgroups_count: count,
              cgroups_hierarchy_root: hierarchy_root,
              cgroups_memory_limit: memory_bytes,
              cgroups_memory_enabled: true,
              cgroups_cpu_shares: cpu_shares,
              cgroups_cpu_enabled: true,
            }
          )
        end

        it 'populates config file with user specified values' do
          expected_config = {
            mountpoint: mountpoint,
            hierarchy_root: hierarchy_root,
            repositories: {
              count: count,
              memory_bytes: memory_bytes,
              cpu_shares: cpu_shares
            }
          }
          expect(config_toml[:cgroups]).to eq(expected_config)
        end
      end

      context 'using new cgroup settings' do
        let(:repositories_memory_bytes) { 1048576 }
        let(:repositories_cpu_shares) { 128 }

        before do
          stub_gitlab_rb(
            gitaly: {
              cgroups_mountpoint: mountpoint,
              cgroups_hierarchy_root: hierarchy_root,
              cgroups_memory_bytes: memory_bytes,
              cgroups_cpu_shares: cpu_shares,
              cgroups_repositories_count: count,
              cgroups_repositories_memory_bytes: repositories_memory_bytes,
              cgroups_repositories_cpu_shares: repositories_cpu_shares,
            }
          )
        end

        it 'populates config file with user specified values' do
          expected_config = {
            mountpoint: mountpoint,
            hierarchy_root: hierarchy_root,
            memory_bytes: memory_bytes,
            cpu_shares: cpu_shares,
            repositories: {
              count: count,
              memory_bytes: repositories_memory_bytes,
              cpu_shares: repositories_cpu_shares
            }
          }
          expect(config_toml[:cgroups]).to eq(expected_config)
        end

        it 'renders the runit run script with cgroup root creation' do
          expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run').with_content { |content|
            expect(content).to match(%r{mkdir -m 0700 -p #{mountpoint}/memory/#{hierarchy_root}})
            expect(content).to match(%r{mkdir -m 0700 -p #{mountpoint}/cpu/#{hierarchy_root}})
            expect(content).to match(%r{chown foo:bar #{mountpoint}/memory/#{hierarchy_root}})
            expect(content).to match(%r{chown foo:bar #{mountpoint}/cpu/#{hierarchy_root}})
          }
        end
      end
    end

    it 'populates config file with user specified values for pack_objects_cache settings' do
      expected_config = {
        pack_objects_cache: {
          enabled: pack_objects_cache_enabled,
          dir: pack_objects_cache_dir,
          max_age: pack_objects_cache_max_age,
        }
      }

      expect(config_toml).to include(expected_config)
    end

    it_behaves_like "enabled runit service", "gitaly", "root", "root"

    it 'renders the runit run script with user specified values' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/run')
        .with_content(%r{ulimit -n 10000})
    end

    it 'appends timestamp in logs' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitaly/log/run')
        .with_content(%r{exec svlogd -tt /tmp/foobar})
    end
  end
end
