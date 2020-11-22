require 'spec_helper'

$LOAD_PATH << './files/gitlab-ctl-commands/lib'

require 'gitlab_ctl'
require 'gitlab_ctl/util'
require 'gitlab_ctl/set_root_password'

RSpec.describe 'GitlabCtl::SetRootPassword' do
  let(:subject) { GitlabCtl::SetRootPassword.new }
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
    allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(node_attributes_stub)
  end

  describe '.get_password' do
    context 'when passwords do not match' do
      it 'raises warning and exits with exit 1' do
        allow(STDIN).to receive(:tty?).and_return(true)
        allow(STDIN).to receive(:getpass).with('Enter password: ').and_return('foobar')
        allow(STDIN).to receive(:getpass).with('Confirm password: ').and_return('123345')
        allow(GitlabCtl::Util).to receive(:warn).and_return(true)

        expect do
          expect { subject.get_password }.to output(/Passwords do not match/).to_stderr
        end.to raise_error(SystemExit)
      end
    end
  end

  describe '.clean_password' do
    context 'using password with unescaped quotes' do
      let(:subject) { GitlabCtl::SetRootPassword.new }
      before do
        subject.instance_variable_set(:@password, "foo'bar")
      end

      it 'cleans the password to escape quotes' do
        subject.clean_password

        expect(subject.instance_variable_get(:@password)).to eq("foo\\'bar")
      end
    end

    context 'using password with escaped quotes' do
      before do
        subject.instance_variable_set(:@password, "foo\\'bar")
      end

      it 'does nothing' do
        subject.clean_password

        expect(subject.instance_variable_get(:@password)).to eq("foo\\'bar")
      end
    end
  end

  describe '.populate_script' do
    let(:tempfile) { Tempfile.new('gitlab-reset-password-script-') }
    let(:script) do
      <<~EOF
      user = User.find_by_username('root')
      raise "Unable to find user with username 'root'." unless user

      user.update!(password: 'foobar', password_confirmation: 'foobar', password_automatically_set: false)
      EOF
    end

    before do
      subject.instance_variable_set(:@password, "foobar")
      allow(Tempfile).to receive(:new).with('gitlab-reset-password-script-').and_return(tempfile)
      allow(FileUtils).to receive(:chown).with('git', 'git', tempfile.path).and_return(true)
    end

    it 'creates a temp file with script' do
      expect(Tempfile).to receive(:new).with('gitlab-reset-password-script-')

      subject.populate_script

      expect(File.read(tempfile.path)).to eq(script)
    end
  end

  describe '.set_password' do
    let(:successful_command) { spy('command spy', error?: false) }
    let(:failed_command) { spy('command spy', error?: true, stdout: 'Output', stderr: 'Error') }

    it 'calls the rails runner command properly' do
      allow(subject).to receive(:populate_script).and_return('/tmp/gitlab-reset-password-foobar')
      allow(GitlabCtl::Util).to receive(:run_command).with("/opt/gitlab/bin/gitlab-rails runner /tmp/gitlab-reset-password-foobar").and_return(successful_command)

      expect(GitlabCtl::Util).to receive(:run_command).with("/opt/gitlab/bin/gitlab-rails runner /tmp/gitlab-reset-password-foobar")
      expect { subject.set_password }.to output(/Attempting to reset password of user with username 'root'. This might take a few moments./).to_stdout
      expect { subject.set_password }.to output(/Password updated successfully/).to_stdout
    end

    it 'handles errors properly' do
      allow(subject).to receive(:populate_script).and_return('/tmp/gitlab-reset-password-foobar')
      allow(GitlabCtl::Util).to receive(:run_command).with("/opt/gitlab/bin/gitlab-rails runner /tmp/gitlab-reset-password-foobar").and_return(failed_command)

      expect do
        expect { subject.set_password }.to output(/Failed to update password/).to_stderr
        expect { subject.set_password }.to output(/Output/).to_stderr
        expect { subject.set_password }.to output(/Error/).to_stderr
      end.to raise_error(SystemExit)
    end
  end
end
