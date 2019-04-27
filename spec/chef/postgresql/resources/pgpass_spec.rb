require 'chef_helper'

describe 'pgpass' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_pgpass)) do |node|
      node.normal['gitlab']['postgresql']['password'] = 'mypassword'
    end
  end
  let(:fake_userinfo) { Struct.new(:gid, :uid, :dir).new(999, 888, '/home/git') }

  before do
    allow(Etc).to receive(:getpwnam) { fake_userinfo }
  end

  context 'run' do
    context 'when running with create action' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_pgpass_create') }

      it 'creates .pgpass file into git user home folder' do
        expect(chef_run).to create_file('/home/git/.pgpass')
      end

      context 'when customizing the filename' do
        let(:chef_run) { runner.converge('test_postgresql::postgresql_pgpass_geo_create') }

        it 'create .geo-pgpass file into git user home folder' do
          expect(chef_run).to create_file('/home/git/.geo-pgpass')
        end
      end
    end

    context 'when running with delete action' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_pgpass_delete') }

      it 'deletes the .pgpass file from the git user home folder' do
        expect(chef_run).to delete_file('/home/git/.pgpass')
      end
    end
  end
end
