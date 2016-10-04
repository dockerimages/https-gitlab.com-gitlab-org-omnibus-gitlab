require 'chef_helper'

describe 'database_migrations recipe' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'using default settings' do
    it 'runs the migrations' do
      expect(chef_run).to run_bash('migrate gitlab-rails database')
    end
  end

  context 'with auto_migrate off' do
    before { stub_gitlab_rb(gitlab_rails: { auto_migrate: false }) }

    it 'skips running the migrations' do
      expect(chef_run).to_not run_bash('migrate gitlab-rails database')
    end
  end

  it 'runs with the initial_root_password in the environment' do
    stub_gitlab_rb(gitlab_rails: { initial_root_password: '123456789' })
    expect(chef_run).to run_bash('migrate gitlab-rails database').with(
      environment: { 'GITLAB_ROOT_PASSWORD' => '123456789' }
    )
  end

  it 'runs with the initial_root_password and initial_shared_runners_registration_token in the environment' do
    stub_gitlab_rb(
      gitlab_rails: { initial_root_password: '123456789', initial_shared_runners_registration_token: '987654321' }
    )

    expect(chef_run).to run_bash('migrate gitlab-rails database').with(
      environment: { 'GITLAB_ROOT_PASSWORD' => '123456789', 'GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN' => '987654321' }
    )
  end
end
