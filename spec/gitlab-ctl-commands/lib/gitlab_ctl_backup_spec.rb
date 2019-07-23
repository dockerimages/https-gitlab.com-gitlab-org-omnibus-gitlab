require 'chef_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

describe GitlabCtl::Backup do
  let(:etc_backup_path) { '/etc/gitlab/config_backup' }

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(FileUtils).to receive(:chmod)
    allow(FileUtils).to receive(:chown)
    allow(FileUtils).to receive(:mkdir)
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    allow_any_instance_of(Kernel).to receive(:exit!)
    allow(STDOUT).to receive(:write)
  end

  it 'should use proper tar command' do
    expect_any_instance_of(Kernel).to receive(:system).with(
      %r{
        tar\s
        --absolute-names\s
        --verbose\s
        --create\s
        --file\s/etc/gitlab/config_backup/\d{10}_\d{4}_\d{2}_\d{2}.tar\s
        --exclude\s/etc/gitlab/config_backup\s/etc/gitlab
      }x
    )
    GitlabCtl::Backup.perform
  end

  it 'should set proper file mode' do
    expect(FileUtils).to receive(:chmod).with(0600, %r{#{etc_backup_path}/\d{10}_\d{4}_\d{2}_\d{2}.tar})
    GitlabCtl::Backup.perform
  end

  it 'should put proper output' do
    expect(STDOUT).to receive(:write).with(
      %r{Running configuration backup\nCreating configuration backup archive: \d{10}_\d{4}_\d{2}_\d{2}.tar}, "\n"
    )
    GitlabCtl::Backup.perform
  end

  context 'when etc backup path does not exist' do
    before do
      allow(File).to receive(:exist?).with(etc_backup_path).and_return(false)
    end

    it 'should log proper message' do
      expect(STDOUT).to receive(:write).with(
        %r{Could not find '#{etc_backup_path}' directory\. Creating\.}, "\n"
      )
      GitlabCtl::Backup.perform
    end

    it 'should create directory' do
      expect(FileUtils).to receive(:mkdir).with(etc_backup_path, mode: 0700)
      GitlabCtl::Backup.perform
    end

    it 'should set proper owner and group' do
      expect(FileUtils).to receive(:chown).with('root', 'root', etc_backup_path)
      GitlabCtl::Backup.perform
    end

    context 'when /etc/gitlab is NFS share' do
      before do
        allow(STDERR).to receive(:write)
        allow(FileUtils).to receive(:chown).with('root', 'root', etc_backup_path).and_raise(Errno::EPERM)
      end

      it 'should put proper output to STDERR' do
        expect(GitlabCtl::Backup).to receive(:warn).with(
          "Warning: Could not change owner of #{etc_backup_path} to 'root:root'. As a result your backups may be " \
          'accessible to some non-root users.'
        )
        GitlabCtl::Backup.perform
      end
    end
  end

  context 'when etc path does not exist' do
    let(:etc_path) { '/etc/gitlab' }
    before do
      allow(File).to receive(:exist?).with(etc_path).and_return(false)
      allow_any_instance_of(Kernel).to receive(:abort)
    end

    it "should abort with proper message" do
      expect_any_instance_of(Kernel).to receive(:abort).with(
        /Could not find '#{etc_path}' directory. Is your package installed correctly?/
      )
      GitlabCtl::Backup.perform
    end
  end
end
