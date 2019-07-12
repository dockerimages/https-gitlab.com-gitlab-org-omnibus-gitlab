require "http"

module Gitlab
  class DockerImageMemoryMeasurer
    attr_accessor :image_reference, :debug_output_dir, :container_log_file, :pid_command_map_file, :smem_result_file, :container_name

    def initialize(image_reference, debug_output_dir = nil)
      @image_reference = image_reference
      @debug_output_dir = debug_output_dir
      @container_name = 'gitlab_memory_measure'.freeze

      set_debug_output_file_names
    end

    def set_debug_output_file_names
      if debug_output_dir.nil?
        @container_log_file = '/dev/null'
        @pid_command_map_file = nil
        @smem_result_file = nil
      else
        @container_log_file = File.join(debug_output_dir, 'container_setup.log')
        @pid_command_map_file = File.join(debug_output_dir, 'pid_command_map.txt')
        @smem_result_file = File.join(debug_output_dir, 'smem_result.txt')
      end
    end

    def measure
      start_docker_container
      pid_command_hash_array, smem_result_hash_array = container_memory_usage_raw_data

      smem_result_hash_array = add_full_command_and_component_to_smem_result_hash(pid_command_hash_array, smem_result_hash_array)
      sum_by_component_hash_array = sum_memory_by_component(smem_result_hash_array)

      puts smem_sum_hash_as_metrics(sum_by_component_hash_array)
    end

    def start_docker_container
      command = "docker run --detach --hostname gitlab.memory_measure.com --publish 443:443 --publish 80:80 --publish 22:22 --name #{container_name} #{image_reference} >> #{container_log_file}"
      system(command)

      # wait until Gitlab started
      gitlab_started = false
      360.times do
        gitlab_started = check_url_alive("http://docker/api/v4/groups")

        break if gitlab_started

        sleep(1)
      end

      abort 'Gitlab services failed to start within 6 minutes' unless gitlab_started

      # wait until Gitlab is hot. Gitlab services take a while to be `hot` after started.
      sleep(120)
    end

    def check_url_alive(url)
      ret_code = HTTP.get(url).code
    rescue StandardError
      ret_code = nil
    ensure
      ret_code == 200
    end

    # Why we need the USERS_MEASURE_OMNIBUS_MEMORY?
    # Because `smem` only give processes under current user.
    # To get all interested processes information under user `git`, we do `su -c "smem" git`
    # We do `su -c "smem" <user>` for all <user> listed in USERS_MEASURE_OMNIBUS_MEMORY
    USERS_MEASURE_OMNIBUS_MEMORY = ['git', 'gitlab-prometheus', 'gitlab-psql', 'gitlab-redis', 'gitlab-www', 'root'].freeze
    def container_memory_usage_raw_data
      # install smem
      command = "docker exec #{container_name} apt-get update >> #{container_log_file}"
      system(command)
      command = "docker exec #{container_name} apt-get install smem -y >> #{container_log_file}"
      system(command)

      # get uss/pss/rss
      smem_result_hash_array = []
      USERS_MEASURE_OMNIBUS_MEMORY.each do |user|
        smem_command = "docker exec #{container_name} su -s /bin/bash -c \"smem -c 'pid user uss pss rss vss command'\" #{user}"
        smem_result_hash_array_single_user = run_command(smem_command, /\s+/, smem_result_file)
        smem_result_hash_array.concat(smem_result_hash_array_single_user)
      end

      # get <pid, command> map
      # `smem` truncate the `command`, this make it hard to map the process memory usage to the component(like `Unicorn`, `Sidekiq`, etc)
      # Example of `smem` output:
      #     PID User     Command                         Swap      USS      PSS      RSS
      #     316 git      /opt/gitlab/embedded/bin/gi     3504      432      443     1452
      #     312 git      /bin/bash /opt/gitlab/embed      148      240      523     2476
      #
      # We use `ps -ax -o pid -o command` to get processes full command line.
      # Example of `ps -ax -o pid -o command` output
      #     PID COMMAND
      #     312 /bin/bash /opt/gitlab/embedded/bin/gitlab-unicorn-wrapper
      #     316 /opt/gitlab/embedded/bin/gitaly-wrapper /opt/gitlab/embedded/bin/gitaly /var/opt/gitlab/gitaly/config.toml
      #
      # Both results have `pid`, which allow to get `full command` for processes in `smem` result.
      ps_command = "docker exec #{container_name} ps -ax -o \"%p<Pid_Command_Separator>\" -o command"
      pid_command_hash_array = run_command(ps_command, /<Pid_Command_Separator>/, pid_command_map_file)

      [pid_command_hash_array, smem_result_hash_array]
    end

    # run command and parse the stdout to hash array
    def run_command(command, separator_in_output, log_file)
      require 'fileutils'
      require 'open3'
      # make sure the folder exists
      FileUtils.mkdir_p debug_output_dir unless debug_output_dir.nil?

      stdout, stderr, status = Open3.capture3(command)

      append_to_file(log_file, stdout) unless debug_output_dir.nil?
      append_to_file(log_file, stderr) unless debug_output_dir.nil?

      abort stderr unless status.exitstatus.zero?

      stdout_to_hash_array(stdout, separator_in_output)
    end

    def append_to_file(filepath, content)
      if File.exist?(filepath)
        File.write(filepath, content, mode: 'a')
      else
        File.write(filepath, content)
      end
    end

    # convert stdout to hash array
    def stdout_to_hash_array(stdout, separator)
      processes = stdout.split(/\n+/).map { |l| l.strip.split(separator) }
      headers = processes.shift
      processes.map! { |p| Hash[headers.zip(p)] }
    end

    def component_command_patterns
      {
        'unicorn' => /(^unicorn master)|(^unicorn worker)/,
        'sidekiq' => /^sidekiq /,
        'gitaly' => /(^\/opt\/gitlab\/embedded\/bin\/gitaly)|(^ruby \/opt\/gitlab\/embedded\/service\/gitaly-ruby\/bin\/gitaly-ruby)/,
        'prometheus' => /^\/opt\/gitlab\/embedded\/bin\/prometheus/,
        'postgres' => /(^\/opt\/gitlab\/embedded\/bin\/postgres)|(^postgres:)/,
        'gitlab-mon' => /^\[gitlab-monitor\]/,
        'workhorse' => /^\/opt\/gitlab\/embedded\/bin\/gitlab-workhorse/,
        'redis' => /^\/opt\/gitlab\/embedded\/bin\/redis_exporter/
      }
    end

    def find_component(command)
      result = []
      component_command_patterns.each do |component, pattern|
        result << component if command&.match(pattern)
      end

      abort "Command(#{command}) matches more than one components: #{result}. Check component_command_patterns: #{component_command_patterns}." if result.size > 1

      result[0]
    end

    def add_full_command_and_component_to_smem_result_hash(pid_command_hash_array, smem_result_hash_array)
      pid_command_map = {}
      pid_command_hash_array.each do |p|
        pid_command_map[p['PID']] = p['COMMAND']
      end

      smem_result_hash_array.each do |p|
        p['COMMAND'] = pid_command_map[p['PID']]
        p['COMPONENT'] = find_component(p['COMMAND'])
      end

      smem_result_hash_array
    end

    def sum_memory_by_component(smem_result_hash_array)
      results = Hash.new { |h, k| h[k] = { 'USS' => 0, 'PSS' => 0, 'RSS' => 0 } }
      smem_result_hash_array.each do |h|
        cummulative_hash = results[h['COMPONENT']]
        cummulative_hash['USS'] += h['USS'].to_f
        cummulative_hash['PSS'] += h['PSS'].to_f
        cummulative_hash['RSS'] += h['RSS'].to_f
      end

      results
    end

    def smem_sum_hash_as_metrics(smem_sum_hash)
      result = []

      smem_sum_hash.each do |key, value|
        component = key
        next if component.nil?

        uss = value['USS'].to_f.round(1)
        pss = value['PSS'].to_f.round(1)
        rss = value['RSS'].to_f.round(1)

        result << "uss_size_kb{component=\"#{component}\"} #{uss}"
        result << "pss_size_kb{component=\"#{component}\"} #{pss}"
        result << "rss_size_kb{component=\"#{component}\"} #{rss}"
      end

      result
    end
  end
end
