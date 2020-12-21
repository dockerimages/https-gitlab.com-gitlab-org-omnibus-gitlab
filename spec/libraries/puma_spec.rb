# This spec is to test the Redis helper and whether the values parsed
# are the ones we expect
require 'chef_helper'

RSpec.describe 'Redis' do
  let(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { ::Redis }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe '.only_one_allowed!' do
    context 'by default' do
      it 'does not raise an error' do
        expect { chef_run }.not_to raise_error
      end
    end

    context 'when only Puma is enabled' do
      before do
        stub_gitlab_rb(
          puma: { enable: true }
        )
      end
      it 'does not raise an error' do
        expect { chef_run }.not_to raise_error
      end
    end

    context 'when both Puma and Unicorn are enabled' do
      before do
        stub_gitlab_rb(
          puma: { enable: true },
          unicorn: { enable: true }
        )
      end
      it 'raises an error' do
        expect { chef_run }.to raise_error("Only one web server (Puma or Unicorn) can be enabled at the same time!")
      end
    end

    context 'when both Unicorn is enabled without explicitly diabling Puma' do
      before do
        stub_gitlab_rb(
          unicorn: { enable: true }
        )
      end
      it 'raises an error' do
        expect { chef_run }.to raise_error("Only one web server (Puma or Unicorn) can be enabled at the same time!")
      end
    end
  end
end
