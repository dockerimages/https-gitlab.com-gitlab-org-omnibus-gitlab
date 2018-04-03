require 'chef_helper'

describe 'cronie::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('cronie::default') }

  it "should create a spool directory" do
    expect(chef_run).to create_directory("/opt/gitlab/embedded/var/spool/cron").with(
      recursive: true,
      owner: "root"
    )
  end

  it "should create a runit_service" do
    pending("debug this matcher")
    expect(chef_run).to enable_runit_service("cronie").with(
      owner: "root",
      group: "root"
    )
  end
end
