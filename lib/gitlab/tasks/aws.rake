require_relative '../aws_helper.rb'
require_relative '../build/info.rb'
require_relative '../build/check.rb'
require 'omnibus'

namespace :aws do
  desc "Perform operations related to AWS AMI"
  task :process do
    AWSHelper.new('12.7.3', 'ce').process
  end
end
