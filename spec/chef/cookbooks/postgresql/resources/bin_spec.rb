require 'chef_helper'

def stub_pg_files(version)
  allow(Dir).to receive(:glob).and_call_original
  allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/#{version}*").and_return(["/opt/gitlab/embedded/postgresql/#{version}"])
  allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/#{version}/bin/*").and_return(
    %W(
      /opt/gitlab/embedded/postgresql/#{version}/bin/foo_one
      /opt/gitlab/embedded/postgresql/#{version}/bin/foo_two
      /opt/gitlab/embedded/postgresql/#{version}/bin/foo_three
    )
  )
end

RSpec.shared_examples "symlink bin files" do |version, version_description|
  it "symlinks bin files for #{version_description}" do
    allow(::FileUtils).to receive(:ln_sf).and_return(true)

    %w(foo_one foo_two foo_three).each do |pg_bin|
      expect(FileUtils).to receive(:ln_sf).with(
        "/opt/gitlab/embedded/postgresql/#{version}/bin/#{pg_bin}",
        "/opt/gitlab/embedded/bin/#{pg_bin}"
      )
    end

    chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
  end
end

RSpec.describe 'postgresql_bin' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: ['postgresql_bin']) }
  let(:pg_version) { '12' }
  let(:geo_pg_version) { '11' }
  let(:psql_version) { PGVersion.parse('13.3') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    allow(Services).to receive(:enabled?).and_call_original
    allow(Services).to receive(:enabled?).with('postgresql').and_return(true)
    allow(Services).to receive(:enabled?).with('geo_postgresql').and_return(true)

    allow_any_instance_of(PgHelper).to receive(:database_version).and_return(pg_version)
    allow_any_instance_of(GeoPgHelper).to receive(:database_version).and_return(geo_pg_version)
    allow_any_instance_of(PgHelper).to receive(:version).and_return(psql_version)

    stub_pg_files(psql_version.major)
  end

  context 'create' do
    let(:chef_run) { runner.converge('gitlab::config', 'test_postgresql::postgresql_bin_create_postgresql') }
    context "when postgresql['version'] is set" do
      context "to a valid value" do
        before do
          stub_gitlab_rb(
            postgresql: {
              version: '12'
            }
          )

          stub_pg_files('12')
        end

        it 'does not raise warning about missing client libraries' do
          expect(chef_run).not_to run_ruby_block('check_postgresql_version')
        end

        include_examples "symlink bin files", '12', 'specified postgresql version'
      end

      context "to an invalid value" do
        before do
          stub_gitlab_rb(
            postgresql: {
              version: '14'
            }
          )
        end

        it 'raises warning about missing client libraries' do
          expect(LoggingHelper).to receive(:warning).with(/We do not ship client binaries for PostgreSQL/)

          expect(chef_run).to run_ruby_block('check_postgresql_version')
          chef_run.ruby_block('check_postgresql_version').block.call
        end

        include_examples "symlink bin files", '13', 'default psql version'
      end
    end

    context "when postgresql['version'] is not set" do
      context 'when postgresql data directory is not empty' do
        context 'when called from postgresql recipe' do
          before do
            stub_pg_files(pg_version)
          end

          include_examples "symlink bin files", '12', 'postgresql version'
        end

        context 'when called from geo-postgresql recipe' do
          let(:chef_run) { runner.converge('gitlab::config', 'test_postgresql::postgresql_bin_create_geo_postgresql') }

          before do
            stub_pg_files(geo_pg_version)
          end

          include_examples "symlink bin files", '11', 'geo-postgresql version'
        end
      end

      context 'when postgresql data directory is empty but geo-postgresql data directory is not' do
        before do
          allow(Services).to receive(:enabled?).with('postgresql').and_return(false)
        end

        context 'when called from postgresql recipe' do
          include_examples "symlink bin files", '13', 'default psql version'
        end

        context 'when called from geo-postgresql recipe' do
          let(:chef_run) { runner.converge('gitlab::config', 'test_postgresql::postgresql_bin_create_geo_postgresql') }

          before do
            stub_pg_files(geo_pg_version)
          end

          include_examples "symlink bin files", '11', 'geo-postgresql version'
        end
      end
    end

    describe 'gitlab-psql-rc' do
      let(:runner) do
        ChefSpec::SoloRunner.new(step_into: %w(postgresql_bin)) do |node|
          # unix_socket_directory is normally conditionally set in postgresql::enable
          # which is not executed as part of this spec
          node.normal['postgresql']['unix_socket_directory'] = '/var/opt/gitlab/postgresql'
        end
      end

      let(:chef_run) { runner.converge('gitlab::config', 'test_postgresql::postgresql_bin_create_geo_postgresql') }

      let(:content) do
        <<~EOF
          psql_user='gitlab-psql'
          psql_group='gitlab-psql'
          psql_host='/var/opt/gitlab/postgresql'
          psql_port='5432'
        EOF
      end

      it 'creates gitlab-psql-rc with correct values' do
        expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-psql-rc').with_content(content)
      end
    end
  end
end
