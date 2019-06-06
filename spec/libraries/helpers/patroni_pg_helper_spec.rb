require 'chef_helper'

describe PatroniPgHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    chef_run.node.normal['patroni']['enable'] = true
  end


  describe '#is_running?' do
    it 'returns true when patroni is running and pg is ready' do
      stub_service_success_status('patroni', true)
      allow(subject).to receive(:pg_isready?).and_return('true')

      expect(subject.is_running?).to be_truthy
    end

    it 'returns true when patroni is not running and pg is ready' do
      stub_service_success_status('patroni', false)
      allow(subject).to receive(:pg_isready?).and_return(true)

      expect(subject.is_running?).to be_falsey
    end

    it 'returns true when patroni is running and pg is not ready' do
      stub_service_success_status('patroni', true)
      allow(subject).to receive(:pg_isready?).and_return(false)

      expect(subject.is_running?).to be_falsey
    end

    it 'returns true when patroni is not running and pg is not ready' do
      stub_service_success_status('patroni', false)
      allow(subject).to receive(:pg_isready?).and_return(false)

      expect(subject.is_running?).to be_falsey
    end
  end

  describe '#should_notify?' do
    it 'returns true when patroni should be notified and pg is ready' do
      stub_should_notify?('patroni', true)
      allow(subject).to receive(:pg_isready?).and_return(true)

      expect(subject.should_notify?).to be_truthy
    end

    it 'returns false when patroni should not be notified and pg is ready' do
      stub_should_notify?('patroni', false)
      allow(subject).to receive(:pg_isready?).and_return(true)

      expect(subject.should_notify?).to be_falsey
    end

    it 'returns true when patroni should be notified and pg is not ready' do
      stub_should_notify?('patroni', true)
      allow(subject).to receive(:pg_isready?).and_return(false)

      expect(subject.should_notify?).to be_falsey
    end

    it 'returns true when patroni should not be notified and pg is not ready' do
      stub_should_notify?('patroni', false)
      allow(subject).to receive(:pg_isready?).and_return(false)

      expect(subject.should_notify?).to be_falsey
    end
  end

  describe '#reload' do
    it 'calls out to psql_cmd when patroni is running' do
      allow(subject).to receive(:is_running?).and_return(true)

      expect(subject).to receive(:psql_cmd).with(
      	["-d 'template1'",
         %(-c "select pg_reload_conf();" -tA)])
      subject.reload
    end

    it 'does not calls out to psql_cmd when patroni is running' do
      allow(subject).to receive(:is_running?).and_return(false)

      expect(subject).not_to receive(:psql_cmd)
      subject.reload
    end
  end

  describe '#start' do 
    it 'calls patroni start when patroni is not running' do
      allow(subject).to receive(:is_running?).and_return(false)
      expect_any_instance_of(PatroniHelper).to receive(:start)
 
      subject.start
    end

    it 'does not call patroni start when patroni is already running' do
      allow(subject).to receive(:is_running?).and_return(true)
      expect_any_instance_of(PatroniHelper).not_to receive(:start)
 
      subject.start
    end
  end

end