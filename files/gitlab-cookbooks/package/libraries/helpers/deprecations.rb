class Deprecations
  def self.deprecated_settings
    settings = [
      # Format is Old category, Old Setting, New Category, New Setting, Docs URL
      %w(nginx listen_address nginx listen_addresses)
    ]
    settings

  end
end
