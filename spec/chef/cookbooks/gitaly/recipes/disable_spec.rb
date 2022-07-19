require 'chef_helper'

RSpec.describe 'gitaly::disable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    stub_gitlab_rb(
      gitaly: {
        enable: false
      }
    )
  end

  it 'includes gitaly::disable recipe' do
    expect(chef_run).to include_recipe('gitaly::disable')
  end

  it_behaves_like "disabled runit service", "gitaly", "root", "root"

  it 'deletes consul service' do
    expect(chef_run).to delete_consul_service('gitaly')
  end
end
