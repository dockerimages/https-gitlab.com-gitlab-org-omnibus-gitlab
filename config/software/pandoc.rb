#
## Copyright:: Copyright (c) 2017 GitLab Inc.
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name 'pandoc'
default_version '1.19.2.1'

license 'COPYING.md'
license 'COPYRIGHT'

source url: "https://hackage.haskell.org/package/pandoc-#{version}/pandoc-#{version}.tar.gz",
       sha256: '08692f3d77bf95bb9ba3407f7af26de7c23134e7efcdafad0bdaf9050e2c7801'

relative_path "pandoc-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  flags = [ "--prefix=#{install_dir}/embedded",
            "-fembed_data_files",
            "--disable-shared",
            "--disable-executable-dynamic"
          ].join(' ')

  command 'cabal update'
  command 'cabal install --only-dependencies'
  command 'cabal install hsb2hs'

  # Patch Pandoc cabal configuration file to include static flags.
  patch source: 'static_build.patch', target: 'pandoc.cabal'

  command "cabal configure #{flags}", env: env
  command 'cabal build', env: env
  command 'cabal copy'
end
