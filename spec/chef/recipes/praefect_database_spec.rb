require 'chef_helper'

RSpec.describe 'praefect' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when manage database is disabled' do
    before do
      stub_gitlab_rb(
        praefect: {
          sql_user: 'praefect',
          sql_database: 'praefect_production',
          pgbouncer_user: 'praefect_pgbouncer',
          pgbouncer_user_password: 'fakepasswordhash'
        })
    end

    it 'should not create database and users' do
      expect(chef_run).not_to create_postgresql_database('praefect_production')
      expect(chef_run).not_to create_pgbouncer_user('praefect')
    end
  end

  context 'when manage database is enabled but required attributes are missing' do
    before do
      stub_gitlab_rb(
        praefect: {
          manage_database: true,
          pgbouncer_user: 'praefect_pgbouncer',
          pgbouncer_user_password: 'fakepasswordhash'
        })
    end

    it 'should not create database and users' do
      expect(chef_run).not_to create_postgresql_database('praefect_production')
      expect(chef_run).not_to create_pgbouncer_user('praefect')
    end
  end

  context 'when manage database is enabled' do
    before do
      stub_gitlab_rb(
        praefect: {
          manage_database: true,
          sql_database: 'praefect_production',
          pgbouncer_user: 'praefect',
          pgbouncer_user_password: 'fakepasswordhash'
        })
    end

    it 'should create database and users' do
      expect(chef_run).to create_postgresql_database('praefect_production').with(
        helper: an_instance_of(PgHelper)
      )
      expect(chef_run).to create_pgbouncer_user('praefect').with(
        helper: an_instance_of(PgHelper),
        user: 'praefect',
        password: 'fakepasswordhash',
        database: 'praefect_production'
      )
      expect(chef_run).not_to run_ruby_block('warn geo cluster')
    end
  end

  context 'when manage database is enabled and geo-postgresql is enabled' do
    before do
      stub_gitlab_rb(
        roles: %w(application_role geo_primary_role),
        praefect: {
          manage_database: true,
          sql_database: 'praefect_production',
          pgbouncer_user: 'praefect',
          pgbouncer_user_password: 'fakepasswordhash'
        })
    end

    it 'should not create database and users' do
      expect(chef_run).not_to create_postgresql_database('praefect_production')
      expect(chef_run).not_to create_pgbouncer_user('praefect')
    end

    it 'should warn user about limitation' do
      expect(chef_run).to run_ruby_block('warn geo cluster')
    end
  end
end
