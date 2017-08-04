require 'chef_helper'

describe Gitlab do
  context 'when using an attribute_block' do
    it 'sets top level attributes to the provided root' do
      Gitlab.attribute_block('gitlab') do
        expect(Gitlab.attribute('test_attribute')[:parent]).to eq 'gitlab'
      end
      expect(Gitlab['test_attribute']).not_to be_nil
      expect(Gitlab.generate_hash['gitlab']).to include('test-attribute')
    end
  end

  it 'sets top level attributes when no parent is provided' do
    Gitlab.attribute('test_attribute')
    expect(Gitlab['test_attribute']).not_to be_nil
    expect(Gitlab.generate_hash).to include('test-attribute')
  end

  it 'properly defines roles' do
    Gitlab.role('test_node')
    expect(Gitlab['test_node_role']).not_to be_nil
    expect(Gitlab.generate_hash['roles']).to include('test-node')
  end

  it 'supports overriding attribute default configuration' do
    attribute = Gitlab.attribute('test_attribute', parent: 'example', sequence: 40, enable: false, default: '')
    expect(Gitlab['test_attribute']).to eq('')
    expect(attribute).to include(parent: 'example', sequence: 40, enable: false)
  end

  it 'disables ee attributes when EE is not enabled' do
    hide_const('GitlabEE')
    expect(Gitlab.ee_attribute('test_attribute')[:enable]).to eq false
    expect(Gitlab['test_attribute']).not_to be_nil
    expect(Gitlab.generate_hash).not_to include('test-attribute')
  end

  it 'enables ee attributes when EE is enabled' do
    stub_const('GitlabEE', 'constant')
    expect(Gitlab.ee_attribute('test_attribute')[:enable]).to eq true
    expect(Gitlab['test_attribute']).not_to be_nil
    expect(Gitlab.generate_hash).to include('test-attribute')
  end

  it 'sorts attributes by sequence' do
    Gitlab.attribute('last', sequence: 99)
    Gitlab.attribute('other1')
    Gitlab.attribute('first', sequence: -99)
    Gitlab.attribute('other2')

    expect(Gitlab.send(:sorted_settings).first[0]).to eq 'first'
    expect(Gitlab.send(:sorted_settings).last[0]).to eq 'last'
  end

  it 'allows passing a block to the attribute use method' do
    attribute = Gitlab.attribute('test_attribute').use { 'test' }
    expect(attribute.handler).to eq('test')
  end
end
