#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

require "#{Omnibus::Config.project_root}/lib/gitlab/version"

EE = system("#{Omnibus::Config.project_root}/support/is_gitlab_ee.sh")

software_name = EE ? 'gitlab-rails-ee' : 'gitlab-rails'
version = Gitlab::Version.new(software_name)

name 'gitlab-rails-gems'

default_version version.print
source git: version.remote

combined_licenses_file = "#{install_dir}/embedded/lib/ruby/gems/gitlab-gem-licenses"
gemcontents_cmd = "#{install_dir}/embedded/bin/gem contents"

license 'MIT'
license_file 'LICENSE'
license_file combined_licenses_file

dependency 'ruby'
dependency 'bundler'
dependency 'libicu'
dependency 'krb5'
dependency 'libre2'
dependency 'postgresql'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  bundle_without = %w[development test]
  bundle_without << 'mysql' unless EE
  bundle 'config build.rugged --no-use-system-libraries', env: env
  bundle "install --without #{bundle_without.join(' ')} --jobs #{workers} --retry 5", env: env

  # One of our gems, google-protobuf is known to have issues with older gcc versions
  # when using the pre-built extensions. We will remove it and rebuild it here.
  block 'reinstall google-protobuf gem' do
    require 'fileutils'

    current_gem = shellout!("#{embedded_bin('bundle')} show | grep google-protobuf", env: env).stdout
    protobuf_version = current_gem[/google-protobuf \((.*)\)/, 1]
    shellout!("#{embedded_bin('gem')} uninstall --force google-protobuf", env: env)
    shellout!("#{embedded_bin('gem')} install google-protobuf --version #{protobuf_version} --platform=ruby", env: env)

    # Workaround for bug where grpc puts it's extension in the wrong folder when compiled
    # See: https://github.com/grpc/grpc/issues/9998
    grpc_path = shellout!("#{embedded_bin('bundle')} show grpc", env: env).stdout.strip
    lib_dir = File.join(grpc_path, 'src/ruby/lib/grpc')
    bin_dir = File.join(grpc_path, 'src/ruby/bin/grpc')
    if File.exist?(File.join(bin_dir, 'grpc_c.so')) && !File.exist?(File.join(lib_dir, 'grpc_c.so'))
      FileUtils.mkdir_p lib_dir
      FileUtils.mv(File.join(bin_dir, 'grpc_c.so'), File.join(lib_dir, 'grpc_c.so'))
    end

    # Delete unsed shared objects included in grpc gem
    ruby_ver = shellout!("#{embedded_bin('ruby')} -e 'puts RUBY_VERSION.match(/\\d+\\.\\d+/)[0]'", env: env).stdout.chomp
    command "find #{lib_dir} ! -path '*/#{ruby_ver}/*' -name 'grpc_c.so' -type f -print -delete"
  end

  # This patch makes the github-markup gem use and be compatible with Python3
  # We've sent part of the changes upstream: https://github.com/github/markup/pull/919
  patch_file_path = File.join(
    Omnibus::Config.project_root,
    'config',
    'patches',
    'gitlab-rails',
    'gitlab-markup_gem-markups.patch'
  )
  # Not using the patch DSL as we need the path to the gems directory
  command "cat #{patch_file_path} | patch -p1 \"$(#{gemcontents_cmd} gitlab-markup | grep lib/github/markups.rb)\""


end
