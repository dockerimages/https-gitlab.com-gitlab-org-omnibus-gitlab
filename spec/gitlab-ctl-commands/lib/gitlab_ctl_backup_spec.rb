require 'chef_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

describe GitlabCtl::Backup do
  let(:backup_dir_path) { '/etc/gitlab/config_backup' }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(FileUtils).to receive(:chmod)
    allow(FileUtils).to receive(:chown)
    allow(FileUtils).to receive(:mkdir)
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    allow_any_instance_of(Kernel).to receive(:exit!)
    # Don't let messages output during test
    allow(STDOUT).to receive(:write)
  end

  context 'when the backup path is readable by non-root' do
    before do
      allow(GitlabCtl::Backup).to receive(:secure?).and_return(false)
    end
    it 'should warn the administrator' do
      expect { GitlabCtl::Backup.perform }.to output(/WARNING: #{backup_dir_path} may be read by non-root users/).to_stderr
    end
  end

  context 'when the backup path is readable by only root' do
    before do
      allow(GitlabCtl::Backup).to receive(:secure?).and_return(true)
    end

    it 'should use proper tar command' do
      expect_any_instance_of(Kernel).to receive(:system).with(
        %r{
          tar\s
          --absolute-names\s
          --verbose\s
          --create\s
          --file\s/etc/gitlab/config_backup/gitlab_config_\d{10}_\d{4}_\d{2}_\d{2}.tar\s
          --exclude\s/etc/gitlab/config_backup\s/etc/gitlab
        }x
      )
      GitlabCtl::Backup.perform
    end

    it 'should set proper file mode on archive file' do
      expect(FileUtils).to receive(:chmod).with(0600, %r{#{backup_dir_path}/gitlab_config_\d{10}_\d{4}_\d{2}_\d{2}.tar})
      GitlabCtl::Backup.perform
    end

    it 'should notify about archive creation starting' do
      expect { GitlabCtl::Backup.perform }.to output(
        %r{Creating configuration backup archive: gitlab_config_\d{10}_\d{4}_\d{2}_\d{2}.tar}
      ).to_stdout
    end

    it 'should put notify about archive creation completion' do
      expect { GitlabCtl::Backup.perform }.to output(
        %r{Configuration backup archive complete: #{backup_dir_path}/gitlab_config_\d{10}_\d{4}_\d{2}_\d{2}.tar}
      ).to_stdout
    end

    it 'should be able to accept a backup directory path argument' do
      custom_dir = "/TanukisOfUnusualSize"
      expect { GitlabCtl::Backup.perform(custom_dir) }.to output(
        %r{Configuration backup archive complete: #{custom_dir}/gitlab_config_\d{10}_\d{4}_\d{2}_\d{2}.tar}
      ).to_stdout
    end

    context 'when etc backup path does not exist' do
      before do
        allow(File).to receive(:exist?).with(backup_dir_path).and_return(false)
      end

      it 'should log proper message' do
        expect { GitlabCtl::Backup.perform }.to output(
          %r{Could not find '#{backup_dir_path}' directory\. Creating\.}).to_stdout
      end

      it 'should create directory' do
        expect(FileUtils).to receive(:mkdir).with(backup_dir_path, mode: 0700)
        GitlabCtl::Backup.perform
      end

      it 'should set proper owner and group' do
        expect(FileUtils).to receive(:chown).with('root', 'root', backup_dir_path)
        GitlabCtl::Backup.perform
      end

      context 'when /etc/gitlab is NFS share' do
        before do
          allow(STDERR).to receive(:write)
          allow(FileUtils).to receive(:chown).with('root', 'root', backup_dir_path).and_raise(Errno::EPERM)
        end

        it 'should put proper output to STDERR' do
          expect(GitlabCtl::Backup).to receive(:warn).with(
            "Warning: Could not change owner of #{backup_dir_path} to 'root:root'. As a result your backups may be " \
            'accessible to some non-root users.'
          )
          GitlabCtl::Backup.perform
        end
      end
    end
  end

  context 'when etc path does not exist' do
    let(:etc_path) { '/etc/gitlab' }
    it "should abort with proper message" do
      allow(File).to receive(:exist?).with(etc_path).and_return(false)
      expect { GitlabCtl::Backup.perform }.to output(/Could not find '#{etc_path}' directory. Is your package installed correctly?/).to_stderr
    end
  end
end
