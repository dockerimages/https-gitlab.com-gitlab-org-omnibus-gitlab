require 'chef_helper'

describe 'PostgreSQL HA Primary' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['gitlab']['postgresql']['md5_auth_cidr_addresses'] = ['1.1.1.1/0']
      node.set['gitlab']['postgresql']['sql_replication_user'] = 'test_gitlab_replicator'
      node.set['gitlab']['postgresql']['wal_level'] = 'hot_standby'
      node.set['gitlab']['postgresql']['max_wal_senders'] = 5
      node.set['gitlab']['postgresql']['wal_keep_segments'] = 10
      node.set['gitlab']['postgresql']['listen_address'] = '1.2.3.4'
    end.converge('gitlab::default')
  end

  it 'adds the correct host line to pg_hba.conf' do
    expect(chef_run).to render_file(
      '/var/opt/gitlab/postgresql/data/pg_hba.conf'
    )
      .with_content(
        %r{^host    replication test_gitlab_replicator 1.1.1.1/0     md5$}
      )
  end

  it 'creates the replication user' do
    allow_any_instance_of(PgHelper).to receive(:is_running?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:user_exists?).and_return(true)
    allow_any_instance_of(PgHelper).to receive(:user_exists?).with('test_gitlab_replicator').and_return(false)
    expect(chef_run).to run_execute(
      "create test_gitlab_replicator replication user"
    ).with(retries: 20)
  end

  it 'sets the approprriate values in postgresql.conf' do
    expect(chef_run).to render_file(
      '/var/opt/gitlab/postgresql/data/postgresql.conf'
    ).with_content { |content|
      expect(content).to match(/^wal_level = hot_standby$/)
      expect(content).to match(/^max_wal_senders = 5$/)
      expect(content).to match(/^wal_keep_segments = 10$/)
      expect(content).to match(
        %r{^listen_addresses = '1.2.3.4'    # what IP address\(es\) to listen on;$}
      )
    }
  end
end

describe 'Postgresql HA Slave' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['gitlab']['postgresql']['ha_standby'] = true
      node.set['gitlab']['postgresql']['standby_mode'] = 'on'
      node.set['gitlab']['postgresql']['primary_host'] = '1.1.1.1'
      node.set['gitlab']['postgresql']['primary_port'] = '9999'
      node.set['gitlab']['postgresql']['trigger_file'] = '/fake/trigger'
      node.set['gitlab']['postgresql']['sql_replication_user'] = 'real_fake_user'
      node.set['gitlab']['postgresql']['sql_replication_user_password'] = 'real_fake_password'
    end.converge('gitlab-ee::default')
  end

  it 'should include the ha standby recipe' do
    expect(chef_run).to include_recipe('gitlab-ee::ha_standby')
  end

  it 'creates a pgpass file for the replication user' do
    expect(chef_run).to render_file(
      '/var/opt/gitlab/postgresql/.pgpass'
    ).with_content(
      '1.1.1.1:9999:*:real_fake_user:real_fake_password'
    )
  end

  it 'should create recovery.conf with specific values' do
    expect(chef_run).to render_file(
      '/var/opt/gitlab/postgresql/data/recovery.conf'
    ).with_content { |content|
      expect(content).to match(%r{^standby_mode = on$})
      expect(content).to match(
        %r{^primary_conninfo = 'host=1.1.1.1 port=9999 user=real_fake_user'$}
      )
      expect(content).to match(%r{^trigger_file = '/fake/trigger'$})
    }
  end
end
