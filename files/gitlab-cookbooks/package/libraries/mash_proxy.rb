#
# Copyright:: Copyright (c) 2019 GitLab Inc.
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

# Proxy object around VividMash, (the class used in node attributes), to provide deprecations.
# Typically node attributes that are Arrays,Hashes,or Mashes get deep merged and returned in a new Mash, which
# would make it difficult to persist our deprecation handling to the end user. Using a proxy object results in
# the deep merge being avoided, and just our defined object being returned.
module Gitlab
  class MashProxy
    # Deprecate using proxy for a given node path
    def self.deprecate_node_path(node, path, key = nil)
      config = node.read(*path) if node.exist?(*path)
      config = Gitlab::MashProxy.new(config) unless config&.is_a?(Gitlab::MashProxy)

      config.deprecate(key, &Proc.new) if block_given?

      # Need to remove before we write to ensure we can change the value's class type
      # We've saved the existing value already into the proxy
      node.rm(*path)
      node.write(:default, *path, config)
    end

    def initialize(existing_settings = nil)
      @mash = Chef::Node::VividMash.new(existing_settings, self)
    end

    def method_missing(method_name, *args, &block)
      (@mash.respond_to?(method_name) && @mash.send(method_name, *args, &block)) || super
    end

    def respond_to_missing?(method_name, include_private = false)
      @mash.send(:respond_to_missing?, method_name, include_private) || super
    end

    def [](key)
      handle_deprecation if @deprecated
      handle_deprecation(@deprecations[key]) if @deprecations&.keys&.include?(key)

      @mash[key]
    end

    # The current level, OR a subkey can be deprecated
    # This allows us to deprecate and entire level, or just specific keys
    def deprecate(key = nil, &block)
      if key.nil?
        @deprecated = true
        @deprecation_handler = block
      else
        @deprecations ||= {}
        @deprecations[key] = block
      end
    end

    # Don't let chef freeze this object
    def freeze
      nil
    end

    private

    def handle_deprecation(handler = nil)
      handler ||= @deprecation_handler
      handler.call if handler&.respond_to?(:call)
    end
  end
end
