module GitlabCtl
  class Backup
    class << self
      def perform
        abort "Could not find '#{etc_path}' directory. Is your package installed correctly?" unless File.exist?(etc_path)
        unless File.exist?(etc_backup_path)
          puts "Could not find '#{etc_backup_path}' directory. Creating."
          FileUtils.mkdir(etc_backup_path, mode: 0700)
          begin
            FileUtils.chown('root', 'root', etc_backup_path)
          rescue Errno::EPERM
            warn("Warning: Could not change owner of #{etc_backup_path} to 'root:root'. As a result your " \
                 'backups may be accessible to some non-root users.')
          end
        end

        puts "Running configuration backup\nCreating configuration backup archive: #{archive_name}"

        command = "tar --absolute-names --verbose --create --file #{archive_path} " \
                  "--exclude #{etc_backup_path} #{etc_path}"
        status  = system(command)
        FileUtils.chmod(0600, archive_path) if File.exist?(archive_path)

        exit!(1) unless status
      end

      def etc_backup_path
        @etc_backup_path ||= '/etc/gitlab/config_backup'
      end

      def etc_path
        @etc_path ||= '/etc/gitlab'
      end

      def archive_name
        @archive_name ||= "#{Time.now.strftime('%s_%Y_%m_%d')}.tar"
      end

      def archive_path
        @archive_path ||= File.join(etc_backup_path, archive_name)
      end
    end
  end
end
