require 'chef_helper'
require 'spec_helper'
require_relative '../../../files/gitlab-cookbooks/package/libraries/handlers/gitlab'

RSpec.describe GitLabHandler::Attributes do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::config') }
  let(:node) { chef_run.node }
  subject { described_class.new }

  before do
    allow(subject).to receive(:node).and_return(node)
    allow(subject).to receive(:store_public_attributes)
  end

  it 'filters attributes and saves there results' do
    allow(node).to receive(:attributes).and_return(
      {
        "attribute_allowlist" => [
          "tree1/subtree11_good",
          "tree1/subtree12_good",
          "tree2/subtree2_good",
          "tree4",
        ],
      })
    allow(node).to receive(:normal).and_return(
      {
        "tree1" => {
          "subtree11_good" => "string1",
          "subtree11_bad" => "sensitive1",
          "subtree12_good" => {
            "subtree121" => 24,
            "subtree122" => 42
          },
          "subtree12_bad" => {
            "subtree121" => "sensitive2"
          }
        },
        "tree2" => {
          "subtree2_good" => true,
          "subtree2_bad" => false
        },
        "tree3" => true,
        "tree4" => false
      })
    expect(subject).to receive(:store_public_attributes).with(
      {
        "tree1" => {
          "subtree11_good" => "string1",
          "subtree12_good" => {
            "subtree121" => 24,
            "subtree122" => 42
          }
        },
        "tree2" => {
          "subtree2_good" => true
        },
        "tree4" => false
      })

    subject.report
  end
end
