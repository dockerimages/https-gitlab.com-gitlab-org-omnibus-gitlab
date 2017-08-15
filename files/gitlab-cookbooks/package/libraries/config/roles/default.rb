module DefaultRole
  class << self
    def activate
      Services.enable_group(Services::DEFAULT_GROUP)
    end
  end
end
