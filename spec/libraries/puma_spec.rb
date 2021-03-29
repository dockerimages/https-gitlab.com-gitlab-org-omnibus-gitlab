require 'chef_helper'

RSpec.describe 'Puma' do
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

    using RSpec::Parameterized::TableSyntax

    where(:puma_enabled, :unicorn_enabled, :expect_error) do
      true | false | false
      false | true | false
      true | true | true
      nil | true | true
    end

    with_them do
      before do
        unicorn = { unicorn: { enable: unicorn_enabled } } unless unicorn_enabled.nil?
        puma = if puma_enabled.nil?
                 {}
               else
                 { puma: { enable: puma_enabled } }
               end
        stub_gitlab_rb(unicorn.merge(puma))
      end

      context 'with specific web service configurations' do
        it 'raises an error when both Unicorn and Puma are enabled' do
          expect { chef_run }.to raise_error("Only one web server (Puma or Unicorn) can be enabled at the same time!") if expect_error
        end
      end
    end
  end
end
