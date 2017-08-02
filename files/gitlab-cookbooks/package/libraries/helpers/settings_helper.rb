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

require 'mixlib/config'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/mixin/deep_merge'
require 'securerandom'
require 'uri'

module SettingsHelper
  class HandledHash < Hash
    attr_writer :handler

    def use(&block)
      @handler = block
    end

    def handler
      @handler = @handler.call if @handler&.respond_to?(:call)
      @handler
    end
  end

  def self.extended(base)
    class << base
      attr_accessor :roles
      attr_accessor :settings
    end

    base.roles = {}
    base.settings = {}
  end

  def attribute_block(root = nil)
    @_default_parent = root
    yield if block_given?
    @_default_parent = nil
  end

  def role(name, **config)
    @roles[name] = HandledHash.new.merge!(config)
    send("#{name}_role", Mash.new)
    @roles[name]
  end

  def attribute(name, **config)
    @settings[name] = HandledHash.new.merge!(
      { parent: @_default_parent, sequence: 20, enable: true, default: Mash.new }
    ).merge(config)

    send(name.to_sym, @settings[name][:default])
    @settings[name]
  end

  def ee_attribute(name, **config)
    # If is EE package, enable setting
    config = { enable: defined?(GitlabEE) == 'constant' }.merge(config)
    attribute(name, **config)
  end

  def method_missing(method_name, *arguments)
    # Give better message for NilClass errors
    # If there are no arguements passed, this is a 'GET' call, and if
    # there is no matching key in the configuration, then it has not been set (not even to nil)
    # and we will output a nicer error above the exception
    if arguments.length.zero? && !configuration.key?(method_name)
      message = "Encountered unsupported config key '#{method_name}' in /etc/gitlab/gitlab.rb."
      puts "\n  *ERROR*: #{message}\n"
      Chef::Log.error(message)
    end

    # Parent method_missing takes care of setting values for missing methods
    super
  end

  def respond_to_missing?(_method_name, _include_private = false)
    super
  end

  def generate_hash
    results = { "gitlab" => {}, "roles" => {} }
    sorted_settings.each do |key, value|
      next unless value[:enable]

      raise "Attribute parent value invalid" if value[:parent] && !results.key?(value[:parent])
      target = value[:parent] ? results[value[:parent]] : results

      rkey = key.tr('_', '-')
      target[rkey] = Gitlab[key]
    end

    @roles.each do |key, value|
      rkey = key.tr('_', '-')
      results['roles'][rkey] = Gitlab["#{key}_role"]
    end

    results
  end

  def generate_secrets(node_name)
    # guards against creating secrets on non-bootstrap node
    SecretsHelper.read_gitlab_secrets

    sorted_settings.each do |_key, value|
      handler = value.handler
      handler.parse_secrets if handler && handler.respond_to?(:parse_secrets)
    end

    SecretsHelper.write_to_gitlab_secrets
  end

  def generate_config(node_name)
    generate_secrets(node_name)

    sorted_settings.each do |_key, value|
      handler = value.handler
      handler.parse_variables if handler && handler.respond_to?(:parse_variables)
    end

    @roles.each do |_key, value|
      handler = value.handler
      handler.load_role if handler && handler.respond_to?(:load_role)
    end

    # The last step is to convert underscores to hyphens in top-level keys
    generate_hash
  end

  private

  def sorted_settings
    @settings.sort_by { |_k, value| value[:sequence] }
  end
end
