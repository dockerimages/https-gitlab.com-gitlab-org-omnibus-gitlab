name 'chef-bin'
# The version here should be in agreement with /Gemfile.lock so that our rspec
# testing stays consistent with the package contents.
default_version '15.9.17'

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'ruby'
dependency 'rubygems'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  gem 'install chef-bin' \
      " --version '#{version}'" \
      " --clear-sources -s https://packagecloud.io/cinc-project/stable -s https://rubygems.org" \
      " --bindir '#{install_dir}/embedded/bin'" \
      ' --no-document', env: env

  link "#{install_dir}/embedded/bin/cinc-client", "#{install_dir}/embedded/bin/chef-client"
  link "#{install_dir}/embedded/bin/cinc-solo", "#{install_dir}/embedded/bin/chef-solo"
end
