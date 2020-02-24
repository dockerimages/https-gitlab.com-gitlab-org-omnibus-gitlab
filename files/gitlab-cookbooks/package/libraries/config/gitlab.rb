#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require_relative '../helpers/settings_helper.rb'
require_relative 'config.rb'

module Gitlab
  extend(Mixlib::Config)
  extend(SettingsHelper)

  ## Attributes that don't get passed to the node
  node nil
  roles nil
  edition :ce
  git_data_dirs ConfigMash.new

  ## Roles
  GitlabConfig.roles.each do |r|
    generate_component_call('role', r)
  end

  ## Attributes directly on the node
  GitlabConfig.node_attributes.each do |a|
    generate_component_call('attribute', a)
  end

  # Attributes under a parent key
  GitlabConfig.nested_attributes.each do |na|
    name = na[:name]
    attributes = na[:attributes]

    attribute_block name do
      attributes.each do |a|
        ee_attribute = a.key?(:ee_attribute) ? a[:ee_attribute] : false

        if ee_attribute
          generate_component_call('ee_attribute', a)
        else
          generate_component_call('attribute', a)
        end
      end
    end
  end
end
