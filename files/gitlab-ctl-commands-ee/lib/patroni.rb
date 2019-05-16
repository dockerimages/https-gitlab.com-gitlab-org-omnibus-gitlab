require 'mixlib/shellout'

# For testing purposes, if the first path cannot be found load the second
begin
  require_relative '../../omnibus-ctl/lib/gitlab_ctl'
rescue LoadError
  require_relative '../../gitlab-ctl-commands/lib/gitlab_ctl'
end

class Patroni

  attr_accessor :command, :subcommand, :input

  def initialize()
    @patroni_conf = File.join(GitlabCtl::Util.get_public_node_attributes['gitlab']['patroni']['config_directory'], "patroni.yml")
  end

  def patroni_cmd(args)
    runas = if Etc.getpwuid.name.eql?('root')
               'gitlab-psql'
            else
                Etc.getpwuid.name
            end
    command = args[3..-1].join(' ')
    cmd("/opt/gitlab/embedded/bin/patronictl -c #{@patroni_conf} #{command}",runas)
  end


  def cmd(command, user = 'root')
    results = Mixlib::ShellOut.new(
      command,
      user: user,
      cwd: '/tmp',
      # Allow a week before timing out.
      timeout: 604800
    )
    begin
      results.run_command
      results.error!
    rescue Mixlib::ShellOut::ShellCommandFailed
      $stderr.puts "Error running command: #{results.command}"
      $stderr.puts "ERROR: #{results.stderr}" unless results.stderr.empty?
      raise
    rescue Mixlib::ShellOut::CommandTimeout
      $stderr.puts "Timeout running command: #{results.command}"
      raise
    rescue StandardError => se
      puts "Unknown Error: #{se}"
    end
    # repmgr logs most output to stderr by default
    return results.stdout unless results.stdout.empty?
    results.stderr
  end

end