require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands-ee/lib')

require 'consul'

describe Consul do
  before do
    allow(STDIN).to receive(:gets) { 'rspec' }
  end
  describe '#initialize' do
    it 'creates instance based on args' do
      instance = Consul.new([nil, nil, 'consul', 'kv', 'set'])
      expect(instance.command).to eq(Consul::Kv)
      expect(instance.subcommand).to eq('set')
    end
  end

  describe '#execute' do
    it 'calls the method on command' do
      instance = Consul.new([nil, nil, 'consul', 'kv', 'set'])
      instance.command = spy
      expect(instance.command).to receive(:set).with('rspec')
      instance.execute
    end
  end
end

describe Consul::Kv do
  let(:consul_cmd) { '/opt/gitlab/embedded/bin/consul' }

  it 'allows nil values' do
    results = double('results', run_command: [], error!: nil)
    expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} kv put foo ").and_return(results)
    described_class.send(:put, 'foo')
  end
end

describe Consul::Upgrade do
  let(:raft_configs) do
    '{
        "Servers": [
        {
          "ID": "192.168.42.100:8300",
          "Node": "consul0",
          "Address": "192.168.42.100:8300",
          "Leader": true,
          "Voter": true
        },
        {
          "ID": "192.168.42.101:8300",
          "Node": "consul1",
          "Address": "192.168.42.101:8300",
          "Leader": false,
          "Voter": true
        },
        {
          "ID": "192.168.42.102:8300",
          "Node": "consul2",
          "Address": "192.168.42.102:8300",
          "Leader": false,
          "Voter": true
        }
      ]
    }'
  end
  let(:member_configs) do
    '[
      {
        "Name": "consul0",
        "Addr": "192.168.42.100"
      },
      {
        "Name": "consul1",
        "Addr": "192.168.42.101"
      },
      {
        "Name": "consul2",
        "Addr": "192.168.42.102"
      },
      {
        "Name": "database0",
        "Addr": "192.168.42.200"
      },
      {
        "Name": "database1",
        "Addr": "192.168.42.201"
      }
    ]'
  end

  let(:current_node) { "consul0" }
  let(:members_api) { URI("http://127.0.0.1:8500/v1/agent/members") }
  let(:raft_api) { URI("http://127.0.0.1:8500/v1/operator/raft/configuration") }
  let(:consul_cmd) { '/opt/gitlab/embedded/bin/consul' }
  let(:node_attributes) { { 'consul' => { 'rejoin_wait_loops' => 5 } } }

  before do
    allow(Net::HTTP).to receive(:get).with(members_api).and_return(member_configs)
    allow(Net::HTTP).to receive(:get).with(raft_api).and_return(raft_configs)
    allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(node_attributes)
  end

  context "the cluster is healthy" do
    before do
      allow_any_instance_of(Consul::Upgrade).to receive(:healthy?).and_return(true)
      @upgrade = Consul::Upgrade.new(current_node)
    end

    it "contains all configured nodes" do
      expect(@upgrade.nodes.size).to eq(5)
    end

    it "can invoke a graceful leave" do
      results = double('results', run_command: [], error!: nil)
      expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} leave").and_return(results)
      @upgrade.send(:leave)
    end

    it "can receive roll" do
      results = double('results', run_command: [], error!: nil)
      expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} leave").and_return(results)
      described_class.send(:roll)
    end
  end

  context "the cluster is unhealthy" do
    before do
      allow_any_instance_of(Consul::Upgrade).to receive(:healthy?).and_return(false)
      @upgrade = Consul::Upgrade.new(current_node)
    end

    it "will raise error and not roll" do
      double('results', run_command: [], error!: nil)
      expect { Consul::Upgrade.roll }.to output(/will not be rolled due to unhealthy cluster!/).to_stderr.and raise_error
    end
  end
end
