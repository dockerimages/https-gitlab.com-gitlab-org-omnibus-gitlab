require 'chef_helper'

describe 'gitlab::letsencrypt' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'default' do
    it 'does not run' do
      expect(chef_run).not_to include_recipe('letsencrypt::enable')
    end
  end

  context 'enabled' do
    before do
      stub_gitlab_rb(
        external_url: 'https://fakehost.example.com',
        letsencrypt: {
          enable: true
        }
      )
    end

    it 'is included' do
      expect(chef_run).to include_recipe('letsencrypt::enable')
    end

    it 'creates a self signed certificate' do
      expect(chef_run).to create_acme_selfsigned('fakehost.example.com')
    end

    it 'creates a staging certificate' do
      expect(chef_run).to create_acme_ssl_certificate('staging').with(
        path: '/etc/gitlab/ssl/fakehost.example.com.crt-staging',
        key: '/etc/gitlab/ssl/fakehost.example.com.key-staging'
      )
    end

    it 'creates a production certificate' do
      expect(chef_run).to create_acme_ssl_certificate('production').with(
        path: '/etc/gitlab/ssl/fakehost.example.com.crt',
        key: '/etc/gitlab/ssl/fakehost.example.com.key'
      )
    end
  end
end
