require 'chef_helper'

describe 'gitlab::haproxy' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when haproxy is not enabled' do
    it_behaves_like "disabled runit service", "haproxy"

    it 'does not execute the start command' do
      expect(chef_run).to_not run_execute('/opt/gitlab/bin/gitlab-ctl start haproxy').with(retries: 20)
    end

    it 'does not render haproxy config' do
      expect(chef_run).to_not create_template('/var/opt/gitlab/haproxy/haproxy.cfg')
    end
  end

  context 'when haproxy is enabled' do
    before { stub_gitlab_rb(haproxy: { enable: true }) }

    let(:config_template) { chef_run.template('/var/opt/gitlab/haproxy/haproxy.cfg') }

    it_behaves_like "enabled runit service", "haproxy", "root", "root"

    it 'creates default set of directories' do
      expect(chef_run.node['gitlab']['haproxy']['dir'])
        .to eql('/var/opt/gitlab/haproxy')
      expect(chef_run.node['gitlab']['haproxy']['log_directory'])
        .to eql('/var/log/gitlab/haproxy')

      expect(chef_run).to create_directory('/var/log/gitlab/haproxy').with(
        owner: 'haproxy',
        group: 'haproxy',
        mode: '0700'
      )
    end

    it 'creates default user and group' do
      expect(chef_run.node['gitlab']['haproxy']['username'])
        .to eql('haproxy')
      expect(chef_run.node['gitlab']['haproxy']['group'])
        .to eql('haproxy')

      expect(chef_run).to create_group('haproxy').with(
        gid: nil,
        system: true
      )

      expect(chef_run).to create_user('haproxy').with(
        uid: nil,
        gid: 'haproxy',
        home: '/var/opt/gitlab/haproxy',
        system: true
      )
    end

    it 'creates haproxy.cfg template with default values' do
      expect(chef_run).to create_template('/var/opt/gitlab/haproxy/haproxy.cfg').with(
        owner: 'haproxy',
        group: 'haproxy',
        mode: '0644'
      )
      expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/global/)
      expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/user haproxy/)
      expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/group haproxy/)
      expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/chroot \/var\/opt\/gitlab\/haproxy/)
      expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/stats socket \/var\/opt\/gitlab\/haproxy\/admin.sock mode 660 level admin/)
      expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/ca-base \/opt\/gitlab\/embedded\/ssl\/certs\/certs/)
      expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/crt-base \/opt\/gitlab\/embedded\/ssl\/certs\/private/)

      expect(chef_run).to_not render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/defaults/)
      expect(chef_run).to_not render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
        .with_content(/listen/)
    end

    it 'triggers haproxy restart' do
      expect(config_template).to notify('service[haproxy]').to(:restart).delayed
    end

    it 'creates a default VERSION file' do
      expect(chef_run).to create_file('/var/opt/gitlab/haproxy/VERSION').with(
        user: nil,
        group: nil
      )
    end

    it 'executes start command' do
      expect(chef_run).to run_execute('/opt/gitlab/bin/gitlab-ctl start haproxy').with(retries: 20)
    end

    context 'with user configuration' do
      before do
        stub_gitlab_rb(
          haproxy: {
            enable: true,
            global: { home: ['/tmp/user'] },
            defaults: { timeout: [ "connect 5000", "check 30000", "client 90s", "server 1h"]},
            listen: { stats_7331: { bind: ['0.0.0.0:7331'], stats: ["enable", "hide-version", "realm Haproxy\ Statistics", "uri /", "auth admin:PASSWORD", "admin if TRUE"] }}
          }
        )
      end

      it 'creates haproxy.cfg template with default values' do
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/global/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/user haproxy/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/group haproxy/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/chroot \/var\/opt\/gitlab\/haproxy/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/stats socket \/var\/opt\/gitlab\/haproxy\/admin.sock mode 660 level admin/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/ca-base \/opt\/gitlab\/embedded\/ssl\/certs\/certs/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/crt-base \/opt\/gitlab\/embedded\/ssl\/certs\/private/)
      end

      it 'creates haproxy.cfg with user configuration' do
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/home \/tmp\/user/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/timeout connect 5000/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/timeout check 30000/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/timeout client 90s/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/timeout server 1h/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/listen stats_7331/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/stats enable/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/realm Haproxy Statistics/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/uri \//)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/admin if TRUE/)
        expect(chef_run).to render_file('/var/opt/gitlab/haproxy/haproxy.cfg')
          .with_content(/auth admin:PASSWORD/)
      end
    end

    context 'with invalid user configuration' do
      before do
        stub_gitlab_rb(
          haproxy: {
            enable: true,
            global: { home: '/tmp/user' },
            defaults: { timeout: ['connect 5000'] },
            listen: { stats_7331: { bind: ['0.0.0.0:7331'], stats: ["enable", "hide-version"] } }
          }
        )
      end

      it 'raises an error' do
        # TODO This is not testable because we are doing it wrong!
        # We are raising an error from within the template which will give Chef::Mixin::Template::TemplateError
        #
        # SyntaxCheckHelper is a hack that works until it doesn't.
        # Rethink how to verify the validity of supplied values.
      end
    end
  end
end
