require 'chef_helper'

describe 'gitlab-ee::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'shows public attr' do
    def flat_hash(hash, key = [])
      return {key => hash} unless hash.is_a?(Hash)
      hash.inject({}){ |h, value| h.merge! flat_hash(value[-1], key + [value[0]]) }
    end

    data = Chef::Node::VividMash.new({})
    flat_hash(chef_run.node.attributes.public_attr).keys.each do |arr|
      data.write(*arr, chef_run.node.read(*arr))
    end
    puts data.inspect
  end

  context 'postgresql is enabled' do
    context 'pgbouncer will not connect to postgresql' do
      it 'should always include the pgbouncer_user recipe' do
        expect(chef_run).to include_recipe('gitlab-ee::pgbouncer_user')
      end
    end

    context 'pgbouncer will connect to postgresql' do
      before do
        stub_gitlab_rb(
          {
            postgresql: {
              pgbouncer_user_password: 'fakepassword'
            }
          }
        )
      end

      it 'should include the pgbouncer_user recipe' do
        expect(chef_run).to include_recipe('gitlab-ee::pgbouncer_user')
      end
    end
  end
end
