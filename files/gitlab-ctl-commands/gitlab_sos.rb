#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require 'json'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'find'
require 'unicorn'
require 'logger'

add_command 'sos', 'Gather system information and application information for GitLab support', 1 do |cmd_name|
  class MultiIO
    def initialize(*targets)
      @targets = targets
    end     
    def write(*args)
      @targets.each { |t| t.write(*args) }
    end
    def close
      @targets.each(&:close)
    end
  end
  hostname = `hostname`.strip
  report_name = "gitlabsos.#{hostname}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
  # TODO: switch to using latest modified as a sanity measure
  config = JSON.parse(File.read(Dir['/opt/gitlab/embedded/nodes/*.json'].first))
  tmpdir = File.join('/tmp', report_name)
  FileUtils.mkdir_p(tmpdir)
  log_file = File.open(File.join(tmpdir, 'gitlabsos.log'), 'a')
  logger = Logger.new MultiIO.new(STDOUT, log_file)
  logger.level = Logger::INFO
  logger.progname = 'gitlabsos'
  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%Y-%m-%dT%H:%M:%S.%6N')}] #{severity} -- #{progname}: #{msg}\n"
  end    
  # if you intend to add a large file to this list, you'll need to change the
  # file.read call to something that streams rather than slurps
  files = [
    { source: '/opt/gitlab/version-manifest.json', destination: './opt/gitlab/version-manifest.json' },
    { source: '/opt/gitlab/version-manifest.txt', destination: './opt/gitlab/version-manifest.txt' },
    { source: '/var/log/messages', destination: './var/log/messages' },
    { source: '/proc/mounts', destination: 'mount' },
    { source: '/proc/meminfo', destination: 'meminfo' },
    { source: '/proc/cpuinfo', destination: 'cpuinfo' },
    { source: '/etc/selinux/config', destination: './etc/selinux/config' },
    { source: '/proc/sys/kernel/tainted', destination: 'tainted' },
    { source: '/etc/os-release', destination: './etc/os-release' },
    { source: '/etc/fstab', destination: './etc/fstab' },
    { source: '/etc/security/limits.conf', destination: './etc/security/limits.conf' }
  ]
      
  commands = [
    { cmd: 'dmesg -T', result_path: 'dmesg' },
    { cmd: 'uname -a', result_path: 'uname' },
    { cmd: 'su - git -c "ulimit -a"', result_path: 'ulimit' },
    { cmd: 'hostname --fqdn', result_path: 'hostname' },
    { cmd: 'getenforce', result_path: 'getenforce' },
    { cmd: 'sestatus', result_path: 'sestatus' },
    { cmd: 'systemctl list-unit-files', result_path: 'systemctl_unit_files' },
    { cmd: 'uptime', result_path: 'uptime' },
    { cmd: 'df -h', result_path: 'df_h' },
    { cmd: 'free -m', result_path: 'free_m' },
    { cmd: 'ps -eo user,pid,%cpu,%mem,vsz,rss,stat,start,time,wchan:16,command', result_path: 'ps' },
    { cmd: 'netstat -tnpl', result_path: 'netstat' },
    { cmd: 'netstat -i', result_path: 'netstat_i' },
    { cmd: 'vmstat -w 1 10', result_path: 'vmstat' },
    { cmd: 'mpstat -P ALL 1 10', result_path: 'mpstat' },
    { cmd: 'pidstat -l 1 15', result_path: 'pidstat' },
    { cmd: 'iostat -xz 1 10', result_path: 'iostat' },
    { cmd: 'nfsiostat 1 10', result_path: 'nfsiostat' },
    { cmd: 'nfsstat -v', result_path: 'nfsstat' },
    { cmd: 'iotop -aoPqt -b -d 1 -n 10', result_path: 'iotop' },
    { cmd: 'sar -n DEV 1 10', result_path: 'sar_dev' },
    { cmd: 'sar -n TCP,ETCP 1 10', result_path: 'sar_tcp' },
    { cmd: 'lscpu', result_path: 'lscpu' },
    { cmd: 'ntpq -pn', result_path: 'ntpq' },
    { cmd: 'gitlab-ctl status', result_path: 'gitlab_status' }
  ]
      
  logger.info 'Starting gitlabsos report'
  logger.info 'Gathering configuration and system info..'
  files.each do |file_info|
  dest = File.join(tmpdir, file_info[:destination])
  logger.debug "copying file from #{file_info[:source]} to #{dest}"
  result = begin
  # this works better than FileUtils.cp for stuff like /proc/mounts
  File.read(file_info[:source])
  rescue Errno::ENOENT => e
  # file doesn't exist
    e.message
  end
  FileUtils.mkdir_p(File.dirname(dest))
  File.write(dest, result)
  end
      
  logger.info 'Collecting diagnostics. This will probably take a few minutes..'
  commands.each do |cmd_info|
  dest = File.join(tmpdir, cmd_info[:result_path])
  logger.debug "running #{cmd_info[:cmd]} and writing results to #{dest}"
    result = begin
      out, err, _status = Open3.capture3(cmd_info[:cmd])
      out + err
      rescue Errno::ENOENT => e
      logger.warn "command '#{cmd_info[:cmd]}' doesn't exist"
      e.message
    end
    File.write(dest, result)
  end
      
  # this method is used to fetch all values out of a hash for any given key
  # I'm just using it to get custom log directories
  def deep_fetch(hash, key)
    hash.values.map do |obj|
      next if obj.class != Hash  
        if obj.key? key
          obj[key]
        else
          deep_fetch(obj, key)
        end
      end.flatten.compact
  end
      
  logger.info 'Getting GitLab logs..'
  logger.debug 'determining log directories..'
  log_dirs = deep_fetch(config['normal'], 'log_directory').uniq
  log_dirs << '/var/log/gitlab'
  logger.debug "using #{log_dirs}"
      
  log_dirs.each do |log_dir|
    unless Dir.exist?(log_dir) && File.directory?(log_dir)
    logger.warn "log directory '#{log_dir}' does not exist or is not a directory"
    next
  end
      
  logger.debug "searching #{log_dir} for log files.."
    logs = Find.find(log_dir).
    select { |f| File.file?(f) && File.mtime(f) > Time.now - (60 * 60 * 12) && File.basename(f) !~ /.*.gz|^@|lock/ }
    logs.each do |log|
      begin
        logger.debug "processing log - #{log}.."
        last_10_mb = `tail -c 10485760 #{log} | tail -n +2`
        FileUtils.mkdir_p(File.dirname(File.join(tmpdir, log)))
        File.write(File.join(tmpdir, log), last_10_mb)
        rescue => e
          logger.error "could not process log - #{log}"
          logger.error e.message
        end
      end
    end
      
    logger.info 'Getting unicorn worker active/queued stats..'
    socket = '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
    if File.exist?(socket)
      unicorn_socket_report = ''
      begin
        5.times do
          Raindrops::Linux.unix_listener_stats([socket]).each do |_addr, stats|
          unicorn_socket_report << "#{DateTime.now} Active: #{stats.active} Queued: #{stats.queued}\n"
        end
        sleep 3
      end
      rescue => e
        logger.error 'could not get unicorn worker stats'
        logger.error e.message
      end
        File.write(File.join(tmpdir, 'unicorn_stats'), unicorn_socket_report)
      else
        logger.warn "socket #{socket} does not exist"
      end
      
      logger.info 'Report finished.'
      log_file.close
      system("tar -cjf /tmp/#{report_name}.tar.bz2 ./#{File.basename(tmpdir)}", chdir: '/tmp')
      FileUtils.remove_dir(tmpdir)
      puts "/tmp/#{report_name}.tar.bz2"
end