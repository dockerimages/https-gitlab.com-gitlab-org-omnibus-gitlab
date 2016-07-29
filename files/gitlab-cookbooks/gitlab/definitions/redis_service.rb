#
# Copyright:: Copyright (c) 2014 GitLab B.V.
# License:: Apache License, Version 2.0
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

define :redis_service, :redis_user => nil, :redis_group => nil, :redis => {}, :sentinel => {} do
  svc = params[:name]

  redis = params[:redis]
  redis_user = params[:redis_user]
  redis_group = params[:redis_group]
  sentinel = params[:sentinel]

  account "Redis user and group" do
    username redis_user
    uid redis['uid']
    ugid redis_user
    groupname redis_user
    gid redis['gid']
    shell redis['shell']
    home redis['home']
    manage node['gitlab']['manage-accounts']['enable']
  end

  directory redis['dir'] do
    owner redis_user
    group redis_group
    mode "0750"
  end

  directory redis['log_directory'] do
    owner redis_user
    mode "0700"
  end

  redis_config = File.join(redis['dir'], "redis.conf")

  template redis_config do
    source "redis.conf.erb"
    owner redis_user
    mode "0644"
    variables(redis.to_hash)
    notifies :restart, "service[#{svc}]", :immediately if OmnibusHelper.should_notify?(svc)
  end

  runit_service svc do
    down redis['ha']
    template_name 'redis'
    owner redis_user
    group redis_group
    options({
      :service => svc,
      :log_directory => redis['log_directory']
    }.merge(params))
    log_options node['gitlab']['logging'].to_hash.merge(redis.to_hash)
  end

  if sentinel['enable']
    redis_sentinel = File.join(redis['dir'], "sentinel.conf")
    sentinel_svc = "#{svc}-sentinel"

    template redis_sentinel do
      source "redis-sentinel.conf.erb"
      owner redis_user
      mode "0644"
      variables({:redis => redis.to_hash, :sentinel => sentinel.to_hash})
      notifies :restart, "service[#{sentinel_svc}]", :immediately if OmnibusHelper.should_notify?(svc)
    end

    runit_service sentinel_svc do
      down redis['ha']
      template_name 'redis-sentinel'
      options({
        :service => sentinel_svc,
        :log_directory => redis['log_directory']
      })
      log_options node['gitlab']['logging'].to_hash.merge(redis.to_hash)
    end
  end

  if node['gitlab']['bootstrap']['enable']
    execute "/opt/gitlab/bin/gitlab-ctl start #{svc}" do
      retries 20
    end
  end
end
