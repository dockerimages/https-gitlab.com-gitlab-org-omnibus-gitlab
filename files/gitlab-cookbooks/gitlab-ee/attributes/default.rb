#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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
####
# Redis Sentinel
####
default['gitlab']['sentinel']['enable'] = false
default['gitlab']['sentinel']['bind'] = '0.0.0.0'
default['gitlab']['sentinel']['dir'] = '/var/opt/gitlab/sentinel'
default['gitlab']['sentinel']['log_directory'] = '/var/log/gitlab/sentinel'
default['gitlab']['sentinel']['ha'] = false
default['gitlab']['sentinel']['port'] = 26379
default['gitlab']['sentinel']['quorum'] = 1
default['gitlab']['sentinel']['down_after_milliseconds'] = 10000
default['gitlab']['sentinel']['failover_timeout'] = 60000
default['gitlab']['sentinel']['myid'] = nil

####
# HAproxy
####
default['gitlab']['haproxy']['enable'] = false
default['gitlab']['haproxy']['username'] = "haproxy"
default['gitlab']['haproxy']['group'] = "haproxy"
default['gitlab']['haproxy']['uid'] = nil
default['gitlab']['haproxy']['gid'] = nil
default['gitlab']['haproxy']['dir'] = "/var/opt/gitlab/haproxy"
default['gitlab']['haproxy']['log_directory'] = "/var/log/gitlab/haproxy"
default['gitlab']['haproxy']['global'] = nil
default['gitlab']['haproxy']['defaults'] = nil
default['gitlab']['haproxy']['listen'] = nil
