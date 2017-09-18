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
  def self.generate_env_variables(node)

    # List of keys that are necessary. We will be setting a default value for these.
    mattermost_env = {
      'MM_SERVICESETTINGS_SITEURL' => node['gitlab']['mattermost']['service_site_url'].to_s,
      'MM_SERVICESETTINGS_LISTENADDRESS' => "#{node['gitlab']['mattermost']['service_address']}:#{node['gitlab']['mattermost']['service_port']}",
      'MM_TEAMSETTINGS_SITENAME' => node['gitlab']['mattermost']['team_site_name'].to_s,
      'MM_SQLSETTINGS_DRIVERNAME' => node['gitlab']['mattermost']['sql_driver_name'],
      'MM_SQLSETTINGS_DATASOURCE' => node['gitlab']['mattermost']['sql_data_source'].to_s,
      'MM_SQLSETTINGS_DATASOURCEREPLICAS' =>  "#{[ node['gitlab']['mattermost']['sql_data_source_replicas'].map{ |dsr| "\"#{dsr}\"" }.join(',') ]}",
      'MM_SQLSETTINGS_ATRESTENCRYPTKEY' => node['gitlab']['mattermost']['sql_at_rest_encrypt_key'].to_s,
      'MM_LOGSETTINGS_FILELOCATION' => "#{node['gitlab']['mattermost']['log_file_directory']}",
      'MM_FILESETTINGS_DIRECTORY' => node['gitlab']['mattermost']['file_directory'].to_s,
      'MM_GITLABSETTINGS_ENABLE' => node['gitlab']['mattermost']['gitlab_enable'].to_s,
      'MM_GITLABSETTINGS_SECRET' => node['gitlab']['mattermost']['gitlab_secret'].to_s,
      'MM_GITLABSETTINGS_ID' => node['gitlab']['mattermost']['gitlab_id'].to_s,
      'MM_GITLABSETTINGS_SCOPE' => node['gitlab']['mattermost']['gitlab_scope'].to_s,
      'MM_GITLABSETTINGS_AUTHENDPOINT' => node['gitlab']['mattermost']['gitlab_auth_endpoint'].to_s,
      'MM_GITLABSETTINGS_TOKENENDPOINT' => node['gitlab']['mattermost']['gitlab_token_endpoint'].to_s,
      'MM_GITLABSETTINGS_USERAPIENDPOINT' => node['gitlab']['mattermost']['gitlab_user_api_endpoint'].to_s,
    }

    # List of settigns that need not be converted to env variable
    skip_list = %w(enable username group uid gid home database_name env host port)

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

    Gitlab['mattermost'].keys.each do |key|
      unless skip_list.include?(key)
        new_key = exceptions[key] || key

        split = new_key.split("_")
        category = split[0].upcase
        value = split[1..-1].join("").upcase
        # Generate env variable of the format MM_<category>_<setting>
        env_string = "MM_#{category}SETTINGS_#{value}"
        mattermost_env[env_string] ||= Gitlab['mattermost'][key].to_s
      end
    end
    mattermost_env
  end
end
