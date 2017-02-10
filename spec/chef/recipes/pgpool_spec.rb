#
# Copyright:: Copyright (c) 2017 GitLab Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef_helper'

describe 'pgpool' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['gitlab']['pgpool']['enable'] = true
    end.converge('gitlab-ee::default')
  end

  before(:each) do
    allow(Gitlab).to receive(:[]).and_call_original
  end

#  context 'by default' do
#    it_behaves_like 'disabled runit service', 'pgpool', 'root', 'root'
#
#    it 'should include the pgpool_disable recipe' do
#      expect(chef_run).to include_recipe 'gitlab-ee::pgpool_disable'
#    end
#  end

  context 'when enabled' do
    before do
      stub_gitlab_rb(
        pgpool: {
          enable: true
        }
      )
    end

    it_behaves_like 'enabled runit service', 'pgpool', 'root', 'root'

    it 'should include the pgpool recipe' do
      expect(chef_run).to include_recipe 'gitlab-ee::pgpool'
    end

    it 'should have a pgpool.conf file' do
      expect(chef_run).to render_file('/var/opt/gitlab/pgpool/pgpool.conf')
    end

    it 'should have a pcp.conf file' do
      expect(chef_run).to render_file('/var/opt/gitlab/pgpool/pcp.conf')
    end
  end
end
