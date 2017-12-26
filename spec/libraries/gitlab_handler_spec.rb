require 'chef_helper'
require_relative '../../files/gitlab-cookbooks/package/libraries/handlers/gitlab'

describe GitLabHandler::HealthCheck do
  let(:passing) do
    {
      examples: [
        {
          status: 'passed'
        }
      ]
    }
  end

  let(:failing) do
    {
      examples: [
        {
          status: 'failed',
          full_description: 'This is the first fake test'
        },
        {
          status: 'passed'
        },
        {
          status: 'failed',
          full_description: 'This is the third fake test'
        }
      ]
    }
  end

  before do
    # Rainbow disables itself in our test env. Force it to enable so we can ensure it is working
    Rainbow.enabled = true
    @handler = GitLabHandler::HealthCheck.new
    @node = Chef::Node.build('chef.handler.gitlabhandler.healthcheck')
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @run_status = Chef::RunStatus.new(@node, @events)
    @run_status.run_context = @run_context
  end

  context 'no failures' do
    before do
      good_results = double(stdout: passing.to_json)
      allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out).with(
        '/opt/gitlab/embedded/bin/rspec --format j /opt/gitlab/embedded/health_checks'
      ).and_return(good_results)
      @handler.run_report_unsafe(@run_status)
    end

    it 'should print out a successful  message' do
      expect { @handler.report }.to output("\e[32mHealth check complete, no issues found\e[0m\n").to_stdout
    end
  end

  context 'failures' do
    before do
      bad_results = double(stdout: failing.to_json)
      allow_any_instance_of(Chef::Mixin::ShellOut).to receive(:shell_out).with(
        '/opt/gitlab/embedded/bin/rspec --format j /opt/gitlab/embedded/health_checks'
      ).and_return(bad_results)
      @handler.run_report_unsafe(@run_status)
    end

    it 'should print out a list of failures' do
      expect { @handler.report }.to output(<<-EOF
\e[33mThere was an issue detected:\e[0m
\e[33mThis is the first fake test\e[0m
\e[33mThis is the third fake test\e[0m
\e[33mPlease see https://docs.gitlab.com/omnibus/maintenance/health_check.html for more information\e[0m
      EOF
                                          ).to_stderr
    end
  end
end
