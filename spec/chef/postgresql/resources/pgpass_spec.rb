require 'chef_helper'

describe 'pgpass' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(postgresql_pgpass)) do |node|
      # unix_socket_directory is normally conditionally set in postgresql::enable
      # which is not executed as part of this spec
      node.normal['gitlab']['postgresql']['password'] = 'mypassword'
    end
  end
  let(:fake_userinfo) { Struct.new(:gid, :uid, :dir).new(999, 888, '/home/git') }

  before do
    allow_any_instance_of(Pgpass).to receive(:userinfo) { fake_userinfo }
  end

  context 'run' do
    context 'when running with create action' do
      let(:chef_run) { runner.converge('test_postgresql::postgresql_pgpass_create') }

      it 'creates .pgpass file into git user home folder' do
        expect(chef_run).to create_file('/home/git/.pgpass')
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
