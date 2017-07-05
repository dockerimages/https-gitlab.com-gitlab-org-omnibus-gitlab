require 'chefspec'
require 'ohai'
require 'fantaskspec'
require 'knapsack'

Knapsack::Adapters::RSpecAdapter.bind if ENV['USE_KNAPSACK']

# Load our Config Object here so we can stub them in our tests
require File.join(__dir__, '../files/gitlab-cookbooks/gitlab/libraries/gitlab.rb')

# Load support libraries to provide common convenience methods for our tests
Dir[File.join(__dir__, 'support/*.rb')].each { |f| require f }

RSpec.configure do |config|
  def mock_file_load(file)
    allow(Kernel).to receive(:load).and_call_original
    allow(Kernel).to receive(:load).with(file).and_return(true)
  end

  ohai_data = Ohai::System.new.tap { |ohai| ohai.all_plugins(['platform']) }.data
  platform, version = *ohai_data.values_at('platform', 'platform_version')

  begin
    Fauxhai.mock(platform: platform, version: version)
  rescue Fauxhai::Exception::InvalidPlatform
    puts "Platform #{platform} #{version} not supported. Falling back to ubuntu 14.04"
    platform = 'ubuntu'
    version = '14.04'
  end

  config.platform = platform
  config.version = version

  config.cookbook_path = ['spec/chef/fixture/', 'files/gitlab-cookbooks/']
  config.log_level = :error

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.include(GitlabSpec::Macros)
end
