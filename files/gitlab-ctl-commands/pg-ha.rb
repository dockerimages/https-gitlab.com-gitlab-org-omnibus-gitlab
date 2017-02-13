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

require 'fileutils'
require 'optparse'
require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"


add_command_under_category 'pg-initialize-standby', 'database',
                           'Run the initial setup of a standby database server',
                           2 do |_cmd_name|

  options = {
    wait: true
  }

  OptionParser.new do |opts|
    opts.on('-w', '--no-wait', 'Do not wait before starting the upgrade process') do
      options[:wait] = false
    end
  end.parse!

  db_worker = GitlabCtl::PgUpgrade.new(base-path, data_path)
  unless options[:wait]
    log "Are you sure? Everything under #{db_worker.data_dir} will be deleted before proceeding"
    log 'Hit Ctrl-C now if this is not what you meant.'
    begin
      30.times do
        $stdout.print '.'
        sleep 1
      end
    rescue Interrupt
      log "\nInterrupt received, cancelling sync"
      exit! 0
    end
  end

  log "Make sure PostgreSQL isn't running"
  run_sv_command_for_service('stop', 'postgresql')

  log 'Removing existing data'
  FileUtils.rmtree Dir.glob("#{db_worker.data_dir}/*")

  log 'Synchronizing from primary host'
  run_command("su - gitlab-psql -c '#{base_path}/embedded/bin/pg_basebackup -h 192.168.50.4 -D #{db_worker.data_dir} -P -U gitlab_replicator --xlog-method=stream'")

  log 'Running reconfigure to reconfigure postgresql'
  # run_chef("#{base_path}/embedded/cookbooks/dna.json")
end
