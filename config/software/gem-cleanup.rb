name 'gem-cleanup'
description 'the steps required to clean unnecessary files after gem builds'
default_version '1.0.0'

license :project_license

build do
  block do
    gem_dir = "#{install_dir}/embedded/lib/ruby/gems/"
    command "echo cleaning ext directories"
    command "find #{gem_dir} -maxdepth 4 -name 'ext' -type d -print -exec rm -rf {}+"
  end
end
