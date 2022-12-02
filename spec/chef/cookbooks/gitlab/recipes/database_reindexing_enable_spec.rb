require 'chef_helper'

RSpec.describe 'gitlab::database-reindexing' do
  let(:chef_run) { converge_config('gitlab::database_reindexing_enable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with defaults' do
    before do
      stub_gitlab_rb(gitlab_rails: { database_reindexing: { enable: true } })
    end

    it 'adds a crond_job with default schedule' do
      expect(chef_run).to create_crond_job('database-reindexing').with(
        user: "root",
        hour: '*',
        minute: 0,
        month: '*',
        day_of_month: '*',
        day_of_week: '0,6',
        command: "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
      )
    end
  end

  context 'with specific schedule' do
    let(:config) do
      {
        enable: true,
        hour: 10,
        minute: 5,
        month: 3,
        day_of_month: 2,
        day_of_week: 1
      }
    end

    it 'adds a crond_job with the configured schedule' do
      stub_gitlab_rb(gitlab_rails: { database_reindexing: config })

      expect(chef_run).to create_crond_job('database-reindexing').with(
        user: "root",
        hour: 10,
        minute: 5,
        month: 3,
        day_of_week: 1,
        command: "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
      )
    end
  end

  context 'with multiple schedules' do
    let(:config) do
      {
        enable: true,
        schedules: [
          {
            hour: '20-24',
            minute: 12,
            day_of_week: 5,
          },
          {
            hour: '*',
            minute: 12,
            day_of_week: 6,
          },
          {
            hour: '0-18',
            minute: 12,
            day_of_week: 0,
          }
        ]
      }
    end

    it 'adds crond files for all scheduled times' do
      stub_gitlab_rb(gitlab_rails: { database_reindexing: config })

      expect(chef_run).to create_crond_job('database-reindexing-0').with(
        user: "root",
        hour: '20-24',
        minute: 12,
        month: '*',
        day_of_week: 5,
        command: "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
      )
      expect(chef_run).to create_crond_job('database-reindexing-1').with(
        user: "root",
        hour: '*',
        minute: 12,
        month: '*',
        day_of_week: 6,
        command: "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
      )
      expect(chef_run).to create_crond_job('database-reindexing-2').with(
        user: "root",
        hour: '0-18',
        minute: 12,
        month: '*',
        day_of_week: 0,
        command: "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
      )
    end

    it 'the default cronjob should not exist' do
      stub_gitlab_rb(gitlab_rails: { database_reindexing: config })

      expect(File).not_to exist("/var/opt/gitlab/crond/database-indexing")
    end
  end
end
