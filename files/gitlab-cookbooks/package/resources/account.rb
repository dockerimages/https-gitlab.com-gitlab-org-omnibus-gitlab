#
# Copyright:: Copyright (c) 2016 GitLab Inc
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

resource_name :account
provides :account

actions :create, :remove
default_action :create

property :username, [String, nil], default: nil
property :uid_value, [String, nil], default: nil
property :ugid_value, [String, nil], default: nil
property :groupname, [String, nil], default: nil
property :gid_value, [String, nil], default: nil
property :shell_value, [String, nil], default: nil
property :home_dir, [String, nil], default: nil
property :append_to_group, [true, false], default: false
property :system_group, [true, false], default: true
property :group_members, Array, default: []
property :user_supports, Hash, default: {}
property :manage, [true, false, nil], default: nil

action :create do
  if manage && groupname
    group groupname do
      group_name groupname
      gid gid_value
      system system_group
      if append_to_group
        append true
        members group_members
      end
      action :create
    end
  end

  if manage && username
    user username do
      username username
      shell shell_value
      home home_dir
      uid uid_value
      gid ugid_value
      system system_group
      supports user_supports
      action :create
    end
  end
end

action :remove do
  if manage && groupname
    group groupname do
      group_name groupname
      action :remove
    end
  end

  if manage && username
    user username do
      username username
      action :remove
    end
  end
end
