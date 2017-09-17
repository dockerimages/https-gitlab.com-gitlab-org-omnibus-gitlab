require_relative 'authorizer_helper'

class MattermostHelper
  extend ShellOutHelper
  extend AuthorizeHelper

  def self.authorize_with_gitlab(gitlab_external_url)
    redirect_uri = "#{Gitlab['mattermost_external_url']}/signup/gitlab/complete\r\n#{Gitlab['mattermost_external_url']}/login/gitlab/complete"
    app_name = 'GitLab Mattermost'

    o = query_gitlab_rails(redirect_uri, app_name)

    app_id, app_secret = nil
    if o.exitstatus == 0
      app_id, app_secret = o.stdout.chomp.split(" ")

      Gitlab['mattermost']['gitlab_enable'] = true
      Gitlab['mattermost']['gitlab_secret'] = app_secret
      Gitlab['mattermost']['gitlab_id'] = app_id
      Gitlab['mattermost']['gitlab_scope'] = ""

      SecretsHelper.write_to_gitlab_secrets
      info('Updated the gitlab-secrets.json file.')
    else
      warn('Something went wrong while trying to update gitlab-secrets.json. Check the file permissions and try reconfiguring again.')
    end
  end

  # Method to generate necessary env variables from settings defined in
  # gitlab.rb
  def self.generate_env_variables
    # List of keys that are necessary. We will be setting a default value for these.
    skip_list = %w(enable username group uid gid home database_name env
                    service_site_url team_site_name sql_driver_name sql_data_source
                    sql_data_source_replicas log_file_directory file_directory gitlab_enable
                    gitlab_secret gitlab_id gitlab_scope gitlab_auth_endpoint
                    gitlab_token_endpoint gitlab_user_api_endpoint)

    # List of keys that doesn't follow the standard naming convention
    exceptions = {
      'service_lets_encrypt_cert_cache_file': 'service_lets_encrypt_certificate_cache_file',
      'log_console_enable': 'log_enable_console',
      'email_enable_batching': 'email_enable_email_batching',
      'ratelimit_enable_rate_limiter': 'ratelimit_enable',
      'webrtc_gateway_stun_uri': 'webrtc_stun_uri',
      'webrtc_gateway_turn_uri': 'webrtc_turn_uri',
      'webrtc_gateway_turn_username': 'webrtc_turn_username',
      'webrtc_gateway_turn_shared_key': 'webrtc_turn_shared_key'
    }

    mattermost_env = {}
    Gitlab['mattermost'].keys.each do |key|
      unless skip_list.include?(key)
        new_key = exceptions[key] || key

        split = new_key.split("_")
        category = split[0].upcase
        value = split[1..-1].join("").upcase
        # Generate env variable of the format MM_<category>_<setting>
        env_string = "MM_#{category}SETTINGS_#{value}"
        mattermost_env[env_string] = Gitlab['mattermost'][key]
      end
    end
    mattermost_env
  end
end
