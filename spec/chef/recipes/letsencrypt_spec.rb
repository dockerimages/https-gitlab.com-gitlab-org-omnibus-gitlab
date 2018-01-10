require 'chef_helper'

describe 'gitlab::letsencrypt' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  context 'default' do
    it 'does not run' do
      expect(chef_run).not_to include_recipe('gitlab::letsencrypt')
    end
  end

  context 'enabled' do
    before do
      stub_gitlab_rb(
        letsencrypt: {
          enabled: true
        }
      )
    end

    it 'is included' do
      expect(chef_run).to include_recipe('gitlab::letsencrypt')
    end
  end
end
