#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

require_relative '../../package/libraries/helpers/secrets_helper'

module GitlabKas
  class << self
    def parse_variables
      parse_address
      parse_gitlab_kas_enabled
      parse_gitlab_kas_external_url
      parse_gitlab_kas_internal_url
      # parse_gitlab_kas_external_k8s_proxy_url
    end

    def parse_address
      Gitlab['gitlab_kas']['gitlab_address'] ||= Gitlab['external_url']
    end

    def parse_gitlab_kas_enabled
      # explicitly enabled or disabled, possibly external to this Omnibus instance
      key = 'gitlab_kas_enabled'
      return unless Gitlab['gitlab_rails'][key].nil?

      # implicitly enable if installed and gitlab integration not explicitly disabled
      Gitlab['gitlab_rails'][key] = gitlab_kas_attr('enable')
    end

    def parse_gitlab_kas_external_url
      key = 'gitlab_kas_external_url'

      return unless Gitlab[key]

      kas_url = Gitlab[key].to_s
      kas_uri = URI(url)

      raise "GitLab KAS external URL must include a scheme and FQDN, e.g. https://registry.example.com/" unless uri.host

      Gitlab['gitlab_kas']['host'] ||= uri.host
      Gitlab['gitlab_kas']['port'] ||= uri.port

      case uri.scheme
      when 'http'
        Gitlab['gitlab_kas_nginx']['https'] ||= false
        Nginx.parse_proxy_headers('gitlab_kas_nginx', false)
      when 'https'
        Gitlab['gitlab_kas_nginx']['https'] ||= true
        Gitlab['gitlab_kas_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['gitlab_kas_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
        Nginx.parse_proxy_headers('gitlab_kas_nginx', true)
      else
        raise "external_url scheme should be 'http' or 'https', got '#{uri.scheme}"
      end

      LetsEncryptHelper.add_service_alt_name('gitlab_kas')

      Gitlab['gitlab_rails'][key] = kas_url
      Gitlab['gitlab_rails']['gitlab_kas_external_k8s_proxy_url'] = "#{kas_url}/k8s-proxy"
    end

    def parse_gitlab_kas_internal_url
      key = 'gitlab_kas_internal_url'
      return unless Gitlab['gitlab_rails'][key].nil?

      return unless gitlab_kas_attr('enable')

      network = gitlab_kas_attr('internal_api_listen_network')
      case network
      when 'tcp'
        scheme = 'grpc'
      else
        raise "gitlab_kas['internal_api_listen_network'] should be 'tcp' got '#{network}'"
      end

      address = gitlab_kas_attr('internal_api_listen_address')
      Gitlab['gitlab_rails'][key] = "#{scheme}://#{address}"
    end

    # def parse_gitlab_kas_external_k8s_proxy_url
    #   key = 'gitlab_kas_external_k8s_proxy_url'
    #   return unless Gitlab['gitlab_rails'][key].nil?

    #   return unless gitlab_kas_attr('enable')

    #   gitlab_external_url = Gitlab['external_url']
    #   return unless gitlab_external_url

    #   # For now, the default external proxy URL is on the subpath /-/kubernetes-agent/k8s-proxy/
    #   # See https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5784
    #   Gitlab['gitlab_rails'][key] = "#{gitlab_external_url}/-/kubernetes-agent/k8s-proxy/"
    # end

    def parse_secrets
      # KAS and GitLab expects exactly 32 bytes, encoded with base64

      Gitlab['gitlab_kas']['api_secret_key'] ||= Base64.strict_encode64(SecretsHelper.generate_hex(16))
      api_secret_key = Base64.strict_decode64(Gitlab['gitlab_kas']['api_secret_key'])
      raise "gitlab_kas['api_secret_key'] should be exactly 32 bytes" if api_secret_key.length != 32

      Gitlab['gitlab_kas']['private_api_secret_key'] ||= Base64.strict_encode64(SecretsHelper.generate_hex(16))
      private_api_secret_key = Base64.strict_decode64(Gitlab['gitlab_kas']['private_api_secret_key'])
      raise "gitlab_kas['private_api_secret_key'] should be exactly 32 bytes" if private_api_secret_key.length != 32
    end

    private

    def gitlab_kas_attr(key)
      configured = Gitlab['gitlab_kas'][key]
      return configured unless configured.nil?

      Gitlab['node']['gitlab-kas'][key]
    end
  end
end
