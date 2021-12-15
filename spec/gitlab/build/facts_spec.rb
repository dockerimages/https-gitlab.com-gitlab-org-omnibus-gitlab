require 'spec_helper'
require 'gitlab/build/facts'

RSpec.describe Build::Facts do
  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe '.generate' do
    it 'calls necessary methods' do
      expect(described_class).to receive(:generate_tag_files)

      described_class.generate
    end
  end

  describe '.generate_tag_files' do
    before do
      allow(Build::Info).to receive(:latest_stable_tag).and_return('14.6.2+ce.0')
      allow(Build::Info).to receive(:latest_tag).and_return('14.7.0+rc42.ce.0')
    end

    it 'writes tag details to file' do
      expect(File).to receive(:write).with('build_facts/latest_stable_tag', '14.6.2+ce.0')
      expect(File).to receive(:write).with('build_facts/latest_tag', '14.7.0+rc42.ce.0')

      described_class.generate_tag_files
    end
  end
end
