$LOAD_PATH << File.join(__dir__, '../../files/gitlab-cookbooks/package/libraries')
require 'node_settings'

describe NodeSettings do
  describe '.traverse' do
    it "walks a 1-level hash" do
      path = []
      subject.class.send(:traverse, { foo: 1, bar: 2 }) { |k, v| path << [k, v] }
      expect(path).to eq([[[:bar], 2], [[:foo], 1]])
    end

    it "walks a multi-level hash" do
      path = []
      subject.class.send(
        :traverse,
        {
          foo: { foo: 1, bar: 2 },
          bar: 3,
          baz: { foo: 4, bar: 5 }
        }) { |k, v| path << [k, v] }
      expect(path).to eq(
        [
          [[:baz, :bar], 5],
          [[:baz, :foo], 4],
          [[:bar], 3],
          [[:foo, :bar], 2],
          [[:foo, :foo], 1],
        ])
    end
  end

  describe '.node_transaction' do
    it 'deletes existing settings' do
      expect(subject.class.send(:node_transaction, 'example.gitlab', {})).to eq(
        [
          { KV: { Verb: 'delete-tree', Key: 'gitlab/nodes/example.gitlab' } }
        ])
    end

    it 'sets new values' do
      settings = {
        gitlab_rails: {
          enabled: true,
          theme: 2,
        }
      }
      expect(subject.class.send(:node_transaction, 'example.gitlab', settings)).to eq(
        [
          { KV: { Verb: 'delete-tree', Key: 'gitlab/nodes/example.gitlab' } },
          {
            KV: {
              Verb: 'set',
              Key: 'gitlab/nodes/example.gitlab/gitlab_rails/theme',
              Value: 'Mg==',
            },
          },
          {
            KV: {
              Verb: 'set',
              Key: 'gitlab/nodes/example.gitlab/gitlab_rails/enabled',
              Value: 'dHJ1ZQ==',
            },
          }
        ])
    end

    describe '.expand_roles' do
      it 'returns node settings' do
        doc = { 'node_settings' => { 'app1' => { 'example' => false } } }
        expect(described_class.send(:expand_roles, doc)).to eq({ 'app1' => { 'example' => false } })
      end

      it 'returns role settings' do
        pending "Implementation"
        doc = { 'role_settings' => { 'app' => { 'example' => false } },
                'role_assignments' => { 'app' => ['app1'] } }
        expect(described_class.send(:expand_roles, doc)).to eq({ 'app1' => { 'example' => false } })
      end

      it 'returns role settings merged with node settings' do
        pending "Implementation"
        doc = { 'role_settings' => { 'app' => { 'example1' => false,
                                                'example2' => false } },
                'node_settings' => { 'app1' => { 'example1' => true } },
                'role_assignments' => { 'app' => %w(app1 app2) } }
        expect(described_class.send(:expand_roles, doc)).to eq({ 'app1' => { 'example1' => true, 'example2' => false },
                                                                 'app2' => { 'example1' => false, 'example2' => false } })
      end
    end
  end
end
