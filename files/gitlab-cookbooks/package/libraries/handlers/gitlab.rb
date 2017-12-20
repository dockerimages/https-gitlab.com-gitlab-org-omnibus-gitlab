#
# Copyright:: Copyright (c) 2017 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/handler'
require 'rainbow'
require 'rspec'

module GitLabHandler
  class Exception < Chef::Handler
    def report
      return unless run_status.failed?

      $stderr.puts Rainbow('There was an error running gitlab-ctl reconfigure:').red
      $stderr.puts
      $stderr.puts Rainbow(run_status.exception.message).red
      $stderr.puts
    end
  end

  class HealthCheck < Chef::Handler
    def report
      results = JSON.parse(`/opt/gitlab/embedded/bin/rspec --format j /opt/gitlab/embedded/health_checks`)
      failed = results['examples'].select { |x| x['status'].eql?('failed') }

      if failed.empty?
        puts Rainbow('Health check complete, no issues found').green
        return
      end

      $stderr.puts Rainbow('There was an issue detected:').yellow
      failed.each { |x| $stderr.puts Rainbow(x['full_description']).yellow }
      $stderr.puts Rainbow('Please see http://docs/gitlab/com/foo.....').yellow # TODO
    end
  end
end
