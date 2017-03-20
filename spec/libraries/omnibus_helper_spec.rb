require 'chef_helper'
require_relative '../../files/gitlab-cookbooks/gitlab/libraries/omnibus_helper.rb'

describe OmnibusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config') }
  subject { described_class.new(chef_run.node) }

  describe '#user_exists?' do
    it 'returns true when user exists' do
      expect(subject.user_exists?('root')).to be_truthy
    end

    it 'returns false when user does not exist' do
      expect(subject.user_exists?('nonexistentuser')).to be_falsey
    end
  end

  describe '#group_exists?' do
    it 'returns true when group exists' do
      expect(subject.group_exists?('root')).to be_truthy
    end

    it 'returns false when group does not exist' do
      expect(subject.group_exists?('nonexistentgroup')).to be_falsey
    end
  end

  describe '#service_up?' do
    it 'returns true when the service is up' do
      shell_output = double(exitstatus: 0,
                            stdout: 'run: nginx: (pid 7935) 1s; run: log: (pid 1495) 1455559s')
      allow(subject).to receive(:do_shell_out).and_return(shell_output)

      expect(subject.service_up?('nginx')).to be_truthy
    end

    it 'returns false when the service is down' do
      shell_output = double(exitstatus: 0,
                            stdout: 'down: nginx: 252840s, normally up; run: log: (pid 1495) 1455229s')
      allow(subject).to receive(:do_shell_out).and_return(shell_output)

      expect(subject.service_up?('nginx')).to be_falsey
    end

    it 'returns false when the sv itself failed' do
      shell_output = double(exitstatus: 1, stdout: 'fail')
      allow(subject).to receive(:do_shell_out).and_return(shell_output)

      expect(subject.service_up?('nginx')).to be_falsey
    end
  end

  describe '#service_down?' do
    it 'returns true when the service is down' do
      shell_output = double(exitstatus: 0,
                            stdout: 'down: nginx: 252840s, normally up; run: log: (pid 1495) 1455229s')
      allow(subject).to receive(:do_shell_out).and_return(shell_output)

      expect(subject.service_down?('nginx')).to be_truthy
    end

    it 'returns false when the service is up' do
      shell_output = double(exitstatus: 0,
                            stdout: 'run: nginx: (pid 7935) 1s; run: log: (pid 1495) 1455559s')
      allow(subject).to receive(:do_shell_out).and_return(shell_output)

      expect(subject.service_down?('nginx')).to be_falsey
    end

    it 'returns true when the sv itself failed' do
      shell_output = double(exitstatus: 1, stdout: 'fail')
      allow(subject).to receive(:do_shell_out).and_return(shell_output)

      expect(subject.service_down?('nginx')).to be_truthy
    end
  end
end
