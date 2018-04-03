# This shouldn't be needed. We have auto-generation now, no?
def enable_runit_service(resource_name)
  ChefSpec::Matchers::ResourceMatcher.new(:runit_service, :enable, resource_name)
end
