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
      auto_enable
      parse_address
      parse_external_url
    end

    def auto_enable
      # Respect gitlab_kas['enable'] if it was set explicitly
      return unless Gitlab['gitlab_kas']['enable'].nil?

      # Respect gitlab_kas_external_url when it was set explicitly to nil
      return unless Gitlab['gitlab_kas_external_url']

      # Only auto_enable when Let's Encrypt is enabled
      return unless Gitlab['letsencrypt']['enable']

      Gitlab['gitlab_kas']['enable'] = true
    end

    def parse_address
      # GitLab KAS needs to know where GitLab Rails can be reached
      Gitlab['gitlab_kas']['gitlab_address'] ||= Gitlab['external_url']
    end

    def parse_external_url
      return unless Gitlab['gitlab_kas']['enable']

      uri = URI(Gitlab['gitlab_kas_external_url'].to_s)

      raise "GitLab KAS external URL must include a schema and FQDN, e.g. https://registry.example.com/" unless uri.host

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
        raise "Unsupported GitLab KAS external URL scheme: \"#{uri.scheme}\""
      end

      LetsEncryptHelper.add_service_alt_name('gitlab_kas')
    end

    def parse_secrets
      # KAS and GitLab expects exactly 32 bytes, encoded with base64
      Gitlab['gitlab_kas']['api_secret_key'] ||= Base64.strict_encode64(SecretsHelper.generate_hex(16))

      api_secret_key = Base64.strict_decode64(Gitlab['gitlab_kas']['api_secret_key'])
      raise "gitlab_kas['api_secret_key'] should be exactly 32 bytes" if api_secret_key.length != 32
    end
  end
end
