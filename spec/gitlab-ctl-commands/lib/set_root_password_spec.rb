require 'spec_helper'

$LOAD_PATH << './files/gitlab-ctl-commands/lib'

require 'gitlab_ctl'
require 'gitlab_ctl/util'
require 'gitlab_ctl/set_root_password'

RSpec.describe 'GitlabCtl::SetRootPassword' do
  let(:node_attributes_stub) do
    {
      'gitlab' => {
        'user' => {
          'username' => 'git',
          'group' => 'git'
        }
      }
    }
  end

  before do
    allow(STDIN).to receive(:tty?).and_return(true)
    allow(STDIN).to receive(:getpass).with('Enter password: ').and_return('foobar')
    allow(STDIN).to receive(:getpass).with('Confirm password: ').and_return('foobar')
    allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(node_attributes_stub)
  end

  describe '#execute!' do
    it 'uses root as the default username' do
      allow(GitlabCtl::SetRootPassword).to receive(:set_password).and_return(spy('command spy', error?: false))

      expect(GitlabCtl::SetRootPassword).to receive(:set_password).with('root', 'foobar')

      GitlabCtl::SetRootPassword.execute!
    end

    it 'raises warning and exits with exit 1 when passwords do not match' do
      allow(GitlabCtl::Util).to receive(:warn).and_return(true)
      allow(STDIN).to receive(:tty?).and_return(true)
      allow(STDIN).to receive(:getpass).with('Enter password: ').and_return('foobar')
      allow(STDIN).to receive(:getpass).with('Confirm password: ').and_return('12345')
      allow(GitlabCtl::SetRootPassword).to receive(:set_password).and_return(spy('command spy', error?: false))

      expect do
        expect { GitlabCtl::SetRootPassword.execute! }.to output(/Passwords do not match/).to_stderr
      end.to raise_error(SystemExit)
    end

    it 'raises warning when setting password failed' do
      allow(GitlabCtl::SetRootPassword).to receive(:set_password).and_return(spy('command spy', error?: true, stdout: 'Output', stderr: 'Error'))

      expect do
        expect { GitlabCtl::SetRootPassword.execute! }.to output(/Failed to update password/).to_stderr
        expect { GitlabCtl::SetRootPassword.execute! }.to output(/Output/).to_stderr
        expect { GitlabCtl::SetRootPassword.execute! }.to output(/Error/).to_stderr
      end.to raise_error(SystemExit)
    end

    it 'prints success message when setting password succeeded' do
      allow(GitlabCtl::SetRootPassword).to receive(:set_password).and_return(spy('command spy', error?: false))

      expect { GitlabCtl::SetRootPassword.execute! }.to output(/Password updated successfully/).to_stdout
    end
  end

  describe '#get_file_owner_and_group' do
    context 'when reading attribute failed' do
      before do
        allow(GitlabCtl::Util).to receive(:get_node_attributes).and_raise(GitlabCtl::Errors::NodeError)
      end

      it 'raises warning and exits' do
        expect do
          expect { GitlabCtl::SetRootPassword.get_file_owner_and_group }.to output(/Unable to get username and group of user to own script file. Please ensure `sudo gitlab-ctl reconfigure` succeeds before first./).to_stderr
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '#set_password' do
    let(:tempfile) { Tempfile.new('gitlab-reset-password-script-') }
    let(:status) { spy('command spy', error?: false) }

    before do
      allow(GitlabCtl::SetRootPassword).to receive(:get_file_owner_and_group).and_return(['git', 'git'])
      allow(GitlabCtl::Util).to receive(:run_command).and_return(status)
    end

    it 'creates a temp file' do
      allow(Tempfile).to receive(:open).and_return(tempfile.path, status)

      expect(Tempfile).to receive(:open).with('gitlab-reset-password-script-')
      GitlabCtl::SetRootPassword.set_password('foobar', 'mysecretpassword')
    end

    it 'removes the temp file at the end' do
      allow(Tempfile).to receive(:open).and_return(tempfile.path, status)

      expect(FileUtils).to receive(:rm_rf).with(tempfile.path)
      GitlabCtl::SetRootPassword.set_password('foobar', 'mysecretpassword')
    end

    it 'sets permission on script file' do
      expect(FileUtils).to receive(:chown).with('git', 'git', %r{/tmp/gitlab-reset-password-script})
      GitlabCtl::SetRootPassword.set_password('foobar', 'mysecretpassword')
    end

    it 'populates the script with expected content' do
      expected_output = "foobar\nmysecretpassword"

      allow(File).to receive(:open).with(%r{/tmp/gitlab-reset-password-script}, any_args).and_return(tempfile)
      allow(FileUtils).to receive(:rm_rf).and_return(true)
      allow(FileUtils).to receive(:chown).and_return(true)

      GitlabCtl::SetRootPassword.set_password('foobar', 'mysecretpassword')

      expect(File.read(tempfile.path)).to eq(expected_output)
    end

    it 'executes script file using rails runner' do
      allow(File).to receive(:open).with(%r{/tmp/gitlab-reset-password-script}, any_args).and_return(tempfile)
      allow(FileUtils).to receive(:rm_rf).and_return(true)
      allow(FileUtils).to receive(:chown).and_return(true)

      expect(GitlabCtl::Util).to receive(:run_command).with(%r{/opt/gitlab/bin/gitlab-rails runner /opt/gitlab/embedded/service/omnibus-ctl/scripts/set_user_password.rb /tmp/gitlab-reset-password-script})

      GitlabCtl::SetRootPassword.set_password('foobar', 'mysecretpassword')
    end
  end
end
