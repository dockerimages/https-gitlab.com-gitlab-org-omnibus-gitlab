require 'chef_helper'

describe PatroniHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(subject).to receive(:service_name) { 'patroni' }
  end

  describe '#is_running?' do
    it 'returns true when patroni is running' do
      stub_service_success_status('patroni', true)

      expect(subject.is_running?).to be_truthy
    end

    it 'returns false when patroni is not running' do
      stub_service_success_status('patroni', false)

      expect(subject.is_running?).to be_falsey
    end
  end

  describe '#enabled?' do
    it 'returns true when conditions are met' do
      chef_run.node.normal['patroni']['enable'] = true

      expect(subject.enabled?).to be_truthy
    end

    it 'returns false when conditions are not met' do
      chef_run.node.normal['patroni']['enable'] = false

      expect(subject.enabled?).to be_falsey
    end
  end
end
