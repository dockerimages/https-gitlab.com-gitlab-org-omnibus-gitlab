require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands-ee/lib')

require 'consul'

describe Consul do
  before do
    allow(STDIN).to receive(:gets) { 'rspec' }
  end

  describe '#initialize' do
    it 'creates instance based on args' do
      instance = Consul.new([nil, nil, 'consul', 'kv', 'put'])
      expect(instance.command).to eq(Consul::Kv)
      expect(instance.subcommand).to eq('put')
    end
  end

  describe '#execute' do
    it 'calls the method on command' do
      instance = Consul.new([nil, nil, 'consul', 'kv', 'put', 'rspec'])
      instance.command = spy
      expect(instance.command).to receive(:put).with(['rspec'])
      instance.execute
    end

    it 'raises a runtime error if the command does not exist' do
      expect { Consul.new([nil, nil, 'consul', 'magical']) }.to raise_error(RuntimeError, "Magical invalid: consul accepts actions #{Consul.valid_actions.join(', ')}")
    end
  end

  context "setting the subcommand" do
    let(:test_args) { %w[cat dog aardvark] }

    it 'raises an argument error if the subcommand does not exist' do
      expect { Consul.new([nil, nil, 'consul', 'kv', 'yakfarm']) }.to raise_error(ArgumentError, 'yakfarm is not a valid option')
    end

    it 'correct identifies the extra arguments for default subcommands' do
      instance = Consul.new([nil, nil, 'consul', 'upgrade', test_args].flatten)
      expect(instance.extra_args).to eq(test_args)
    end

    it 'correct identifies the extra arguments for a custom subcommand' do
      instance = Consul.new([nil, nil, 'consul', 'kv', 'put', test_args].flatten)
      expect(instance.extra_args).to eq(test_args)
    end
  end
end

describe Consul::Kv do
  let(:consul_cmd) { '/opt/gitlab/embedded/bin/consul' }

  it 'allows nil values' do
    results = double('results', run_command: [], error!: nil)
    expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} kv put foo ").and_return(results)
    described_class.send(:put, ['foo'])
  end

  it 'throws ArgumentError when put is given too many arguments' do
    expect { described_class.send(:put, %w[angry yaks unite]) }.to raise_error(ArgumentError)
  end

  it 'throws ArgumentError when put is given too few arguments' do
    expect { described_class.send(:put, []) }.to raise_error(ArgumentError)
  end

  it 'throws ArgumentError when delete is given too many arguments' do
    expect { described_class.send(:delete, %w[angry yaks]) }.to raise_error(ArgumentError)
  end

  it 'throws ArgumentError when delete is given too few arguments' do
    expect { described_class.send(:delete, []) }.to raise_error(ArgumentError)
  end
end

describe Consul::Upgrade do
  let(:current_node) { "consul0" }
  let(:consul_cmd) { '/opt/gitlab/embedded/bin/consul' }
  let(:hostname) { 'yakhost' }
  let(:healthcheck) { URI('http://127.0.0.1:8500/v1/health/service/consul') }
  let(:health_data) do
    '[
      {
        "Checks": [
          "Node": "consul0",
          "Status": "passing"
        ]
      }
    ]'
  end

  before do
    allow(Socket).to receive(:gethostname).and_return(hostname)
    # tests don't need to wait as everything is mocked
    allow_any_instance_of(Kernel).to receive(:sleep)
    # Don't let messages output during test
    allow(STDOUT).to receive(:puts)
    allow(Net::HTTP).to receive(:get).with(healthcheck).and_return(health_data)
  end

  context "called from gitlab-ctl" do
    context "given no arguments" do
      it "attempts to invoke default method" do
        instance = Consul.new([nil, nil, 'consul', 'upgrade'])
        expect(instance.command).to eq(Consul::Upgrade)
        expect(instance.subcommand).to eq('default')
      end

      it "defaults to 100 second health check timeout" do
        upgrade = Consul::Upgrade.new(current_node, nil)
        expect(upgrade.timeout).to eq(100)
      end
    end

    context "given arguments" do
      it "can retry the health check for an arbitrary number of seconds" do
        upgrade = Consul::Upgrade.new(current_node, ['-t', '200'])
        expect(upgrade.timeout).to eq(200)
      end

      it "defaults to 100 second health check timeout with invalid input" do
        upgrade = Consul::Upgrade.new(current_node, ['-t', 'cat'])
        expect(upgrade.timeout).to eq(100)
      end
    end
  end

  context "the cluster is healthy" do
    before do
      allow_any_instance_of(Consul::Upgrade).to receive(:health_check).and_return(true, true)
      allow_any_instance_of(Consul::Upgrade).to receive(:started_healthy?).and_return(true)
      allow_any_instance_of(Consul::Upgrade).to receive(:finished_healthy?).and_return(true)
      allow_any_instance_of(Consul::Upgrade).to receive(:rolled?).and_return(true)
    end

    it "can invoke a graceful leave" do
      results = double('results', run_command: [], error!: nil)
      expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} leave").and_return(results)
      described_class.send(:default)
    end

    context "the node failed to restart" do
      it "throws a Runtime error" do
        allow_any_instance_of(Consul::Upgrade).to receive(:rolled?).and_return(false)
        results = double('results', run_command: [], error!: nil)
        allow(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} leave").and_return(results)
        expect { described_class.send(:default) }.to raise_error(RuntimeError, "#{hostname} stopped, cluster healthy")
      end
    end

    context "the node restarted properly" do
      it "can do node roll" do
        allow_any_instance_of(Consul::Upgrade).to receive(:rolled?).and_return(true)
        results = double('results', run_command: [], error!: nil)
        expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} leave").and_return(results)
        described_class.send(:default)
      end
    end
  end

  context "the cluster is unhealthy" do
    before do
      allow_any_instance_of(Consul::Upgrade).to receive(:started_healthy?).and_return(false)
    end

    it "will raise error and not roll" do
      double('results', run_command: [], error!: nil)
      expect { Consul::Upgrade.default }.to output(/will not be rolled due to unhealthy cluster!/).to_stderr.and raise_error
    end
  end
end
