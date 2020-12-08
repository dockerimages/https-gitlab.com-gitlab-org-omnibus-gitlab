require 'chef_helper'

RSpec.describe PatroniHelper do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: %w(patroni)).converge('gitlab-ee::default')
  end

  subject(:helper) { PatroniHelper.new(chef_run.node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '#ctl_command' do
    it 'returns a full path to the ctl_command' do
      expect(helper.ctl_command).to eq('/opt/gitlab/embedded/bin/patronictl')
    end
  end

  describe '#bootstrapped?' do
    before do
      allow(File).to receive(:exist?).and_call_original
    end

    it 'returns true when patroni.dynamic.json exists in postgresql data directory' do
      allow(File).to receive(:exist?).with('/var/opt/gitlab/postgresql/data/patroni.dynamic.json').and_return(true)

      expect(helper.bootstrapped?).to eq(true)
    end

    it 'returns false when patroni.dynamic.json does not exist in postgresql data directory' do
      allow(File).to receive(:exist?).with('/var/opt/gitlab/postgresql/data/patroni.dynamic.json').and_return(false)

      expect(helper.bootstrapped?).to eq(false)
    end
  end

  describe '#dynamic_settings' do
    it 'returns a hash with required keys' do
      expected_root_keys = PatroniHelper::DCS_ATTRIBUTES + %w[postgresql slots]

      expect(helper.dynamic_settings.keys).to match_array(expected_root_keys)
    end

    context 'with standby cluster enabled' do
      it 'includes standby cluster attributes' do
        stub_gitlab_rb(
          patroni: {
            enable: true,
            standby_cluster: {
              enable: true
            }
          }
        )

        expected_root_keys = PatroniHelper::DCS_ATTRIBUTES + %w[postgresql slots standby_cluster]

        expect(helper.dynamic_settings.keys).to match_array(expected_root_keys)
      end
    end
  end
end
