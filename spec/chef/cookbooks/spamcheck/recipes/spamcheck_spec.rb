require 'chef_helper'
require 'toml-rb'

RSpec.describe 'spamcheck' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when spamcheck is disabled (default)' do
    it 'includes spamcheck::disable recipe' do
      expect(chef_run).to include_recipe('spamcheck::disable')
    end
  end

  context 'when spamcheck is enabled' do
    before do
      stub_gitlab_rb(
        spamcheck: {
          enable: true
        }
      )
    end

    it 'includes spamcheck::enable recipe' do
      expect(chef_run).to include_recipe('spamcheck::enable')
    end
  end

  describe 'spamcheck::enable' do
    context 'with default values' do
      before do
        stub_gitlab_rb(
          spamcheck: {
            enable: true
          }
        )
      end

      it 'creates necessary directories at default locations' do
        %w[
          /var/opt/gitlab/spamcheck
          /var/log/gitlab/spamcheck
        ].each do |dir|
          expect(chef_run).to create_directory(dir).with(
            owner: 'git',
            mode: '0700',
            recursive: true
          )
        end
      end

      it 'creates config.yaml with default values' do
        actual_content = get_rendered_yaml(chef_run, '/var/opt/gitlab/spamcheck/config.yaml')
        expected_content = {
          filter: {
            allow_list: nil,
            allowed_domains: ["gitlab.com"],
            deny_list: nil
          },
          grpc_addr: "127.0.0.1:8001",
          log_level: "info",
          ml_classifiers: "/opt/gitlab/embedded/service/spam-classifier/classifiers"
        }
        expect(actual_content).to eq(expected_content)
      end

      it 'creates env directory with default variables' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/spamcheck/env').with_variables(
          'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
        )
      end

      it_behaves_like "enabled runit service", "spamcheck", "root", "root"

      it 'creates runit files for spamcheck service' do
        expected_content = <<~EOS
          #!/bin/bash

          # Let runit capture all script error messages
          exec 2>&1

          exec chpst -e /opt/gitlab/etc/spamcheck/env -P \\
            -u git:git \\
            -U git:git \\
            /opt/gitlab/embedded/bin/python3 /opt/gitlab/embedded/service/spamcheck/main.py --config /var/opt/gitlab/spamcheck/config.yaml
        EOS

        expect(chef_run).to render_file('/opt/gitlab/sv/spamcheck/run').with_content(expected_content)
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          user: {
            username: 'randomuser',
            group: 'randomgroup'
          },
          spamcheck: {
            enable: true,
            dir: '/data/spamcheck',
            port: 5001,
            host: "0.0.0.0",
            log_level: 'debug',
            allowlist: {
              '14' => 'spamtest/hello'
            },
            denylist: {
              '15' => 'foobar/random'
            },
            env_directory: '/env/spamcheck',
            log_directory: '/log/spamcheck',
            env: {
              'FOO' => 'BAR'
            }
          }
        )
      end

      it 'creates necessary directories at user specified locations' do
        %w[
          /data/spamcheck
          /log/spamcheck
        ].each do |dir|
          expect(chef_run).to create_directory(dir).with(
            owner: 'randomuser',
            mode: '0700',
            recursive: true
          )
        end
      end

      it 'creates config.yaml with user specified values' do
        actual_content = get_rendered_yaml(chef_run, '/data/spamcheck/config.yaml')
        expected_content = {
          filter: {
            allowed_domains: ["gitlab.com"],
            allow_list: {
              14 => "spamtest/hello"
            },
            deny_list: {
              15 => "foobar/random"
            }
          },
          grpc_addr: "0.0.0.0:5001",
          log_level: "debug",
          ml_classifiers: "/opt/gitlab/embedded/service/spam-classifier/classifiers"
        }
        expect(actual_content).to eq(expected_content)
      end

      it 'creates env directory with user specified and default variables' do
        expect(chef_run).to create_env_dir('/env/spamcheck').with_variables(
          'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
          'FOO' => 'BAR'
        )
      end

      it_behaves_like "enabled runit service", "spamcheck", "root", "root"

      it 'creates runit files for spamcheck service' do
        expected_content = <<~EOS
          #!/bin/bash

          # Let runit capture all script error messages
          exec 2>&1

          exec chpst -e /env/spamcheck -P \\
            -u randomuser:randomgroup \\
            -U randomuser:randomgroup \\
            /opt/gitlab/embedded/bin/python3 /opt/gitlab/embedded/service/spamcheck/main.py --config /data/spamcheck/config.yaml
        EOS

        expect(chef_run).to render_file('/opt/gitlab/sv/spamcheck/run').with_content(expected_content)
      end
    end
  end

  describe 'spamcheck::disable' do
    it_behaves_like "disabled runit service", "spamcheck", "root", "root"
  end
end
