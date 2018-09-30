#
# Copyright:: Copyright (c) 2016 GitLab Inc
# License:: Apache License, Version 2.0
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

require 'optparse'
require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require 'fileutils'

# Sample output of prometheus --version is
# prometheus, version 1.8.2 (branch: master, revision: 6aa68e74cdc25a7d95f3f120ccc8eddd46e3c07b)
VERSION_REGEX = %r{.*?version (?<version>.*?) .*?}

add_command 'prometheus-upgrade', 'Upgrade the Prometheus data to the latest supported version',
  2 do |_cmd_name|

  options = parse_migrator_options
  home_dir = File.expand_path(options[:home_dir])

  unless File.exist?(File.join(home_dir, "data"))
    log "Specified home directory, #{home_dir} either does not exist or does not contain any data directory inside."
    Kernel.exit 1
  end

  if is_version_2?(home_dir)
    log "Already running Prometheus version 2."
    Kernel.exit 0
  end

  unless options[:skip_data_migration]
    log "Converting existing data to new format is a time consuming process and can take hours."
    log "If you prefer not to migrate existing data, press Ctrl-C now and re-run the command with --skip-data-migration flag."
    log "Waiting for 30 seconds for input."
    wait_for_input(30) if options[:wait]
  end

  v1_path = File.join(home_dir, "data")
  v2_path = File.join(home_dir, "data2")
  tmp_path = File.join(home_dir, "data_tmp")

  # Make temporary directory to move data
  FileUtils.mkdir_p(v2_path)
  system("chown --reference=#{v1_path} #{v2_path}")
  system("chmod --reference=#{v1_path} #{v2_path}")

  log "Stopping prometheus for upgrade"
  run_sv_command_for_service('stop', 'prometheus')

  unless options[:skip_data_migration]
    log "Migrating data"
    status = system("#{base_path}/embedded/bin/prometheus-storage-migrator -v1-path=#{v1_path} -v2-path=#{v2_path}")
    unless status
      log "Migration failed. Restarting prometheus."
      run_sv_command_for_service('start', 'prometheus')
      Kernel.exit 1
    end

    system("chown -R --reference=#{v1_path} #{v2_path}")
    log "Migration successful. "
  end

  FileUtils.mv(v1_path, tmp_path)
  FileUtils.mv(v2_path, v1_path)

  log "Running reconfigure to apply changes"

  run_chef("#{base_path}/embedded/cookbooks/dna.json").success?

  log "Starting prometheus"
  run_sv_command_for_service('start', 'prometheus')

  log "Prometheus upgrade completed. You are now running Prometheus version 2"
  log "Old data directory has been backed up to #{tmp_path}. Feel free to delete it after verifying everything is working fine."
end

def parse_migrator_options
  options = {
    skip_data_migration: false,
    home_dir: "/var/opt/gitlab/prometheus",
    wait: true
  }
  OptionParser.new do |opts|
    opts.on('-s', '--skip-data-migration', 'Skip migrating data to Prometheus 2.x format') do
      options[:skip_data_migration] = true
    end

    opts.on('-hDIR', '--home-dir=DIR', "Value of prometheus['home'] set in gitlab.rb") do |d|
      options[:home_dir] = d
    end

    opts.on('-w', '--no-wait', 'Do not wait before starting the upgrade process') do
      options[:wait] = false
    end
  end.parse!(ARGV)

  options
end

def is_version_2?(home_dir)
  version_string_check && file_existence_check(home_dir)
end

def file_existence_check(home_dir)
  File.exist?(File.join(home_dir, "data", "wal"))
end

def version_string_check
  version_output = `#{base_path}/embedded/bin/prometheus --version 2>&1`.strip
  version_output.match(VERSION_REGEX)[:version].start_with?("2")
end

def wait_for_input(seconds)
  seconds.times do
    $stdout.print "."
    sleep 1
  end
rescue Interrupt
  log "\nInterrupt received. Aborting upgrade."
  Kernel.exit 0
end
