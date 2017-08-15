module DefaultRole
  class << self
    def load_role
      # Disable the rails group of services if it has been explicitly set to false
      Services.disable_group('rails') unless Services.enabled?('gitlab_rails')
    end

    def activate
      Services.enable_group(Services::DEFAULT_GROUP)
    end
  end
end
