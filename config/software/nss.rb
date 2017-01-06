#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
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
name 'nss'
default_version '3.28'
nspr_version = '4.13.1'
license 'GPL-2.0'

dependency 'nspr'

version '3.28' do
  source sha256: 'e8fbb4fcf46666b028d43ee13236a5870ccd13b983d179aa49afd0c0cfa0df15'
end

major, minor, patch = version.split('.')

subdir = "pub/security/nss/releases/NSS_#{major}_#{minor}#{patch.nil? ? '' : '_' + patch}_RTM/src"
source url: "https://ftp.mozilla.org/#{subdir}/nss-#{version}-with-nspr-#{nspr_version}.tar.gz"

relative_path "nss-#{version}/nss"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  # Build a 64 bit version, default is still 32
  env['USE_64'] = '1'
  # Don't do a debug build
  env['BUILD_OPT'] = '1'
  env['NSDISTMODE'] = 'copy'
  env['NSS_DISABLE_GTESTS'] = '1'
  make 'nss_build_all', env: env
  block 'install files' do
    %w(bin lib include).each do |dir|
      mkdir "#{install_dir}/embedded/#{dir}"
      copy Dir.glob("#{project_dir}/../dist/*.OBJ/#{dir}/*"), "#{install_dir}/embedded/#{dir}/"
    end
  end
  # Install header files
  mkdir "#{install_dir}/embedded/include/nss/"
  copy "#{project_dir}/../dist/public/nss/*.h", "#{install_dir}/embedded/include/nss/"


  # Install pc file for pkg-config
  mkdir "#{install_dir}/embedded/lib/pkgconfig"
  block 'create nss.pc' do
    nss_pc_in = File.read("#{project_dir}/pkg/pkg-config/nss.pc.in")
    nss_pc_in.gsub!(%r{%prefix%}, "#{install_dir}/embedded")
    nss_pc_in.gsub!(%r{%exec_prefix%}, "#{install_dir}/embedded")
    nss_pc_in.gsub!(%r{%libdir%}, "#{install_dir}/embedded/lib")
    nss_pc_in.gsub!(%r{%includedir%}, "#{install_dir}/embedded/include/nss")
    nss_pc_in.gsub!(%r{%NSS_VERSION%}, version)
    nss_pc_in.gsub!(%r{%NSPR_VERSION%}, nspr_version)
    File.open("#{install_dir}/embedded/lib/pkgconfig/nss.pc", 'w') do |f|
      f.write(nss_pc_in)
    end
  end
end
