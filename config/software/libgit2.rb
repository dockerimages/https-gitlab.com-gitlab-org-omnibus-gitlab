name 'libgit2'

default_version 'v1.1.0'

dependency 'zlib'
dependency 'curl'

source git: 'https://github.com/libgit2/libgit2.git'

license 'GPL-2.0'
license_file 'COPYING'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_command = [
    'cmake',
    "-DCMAKE_INSTALL_LIBDIR:PATH=lib", # ensure lib64 isn't used
    "-DCMAKE_INSTALL_RPATH=#{install_dir}/embedded/lib",
    "-DCMAKE_FIND_ROOT_PATH=#{install_dir}/embedded",
    "-DCMAKE_PREFIX_PATH=#{install_dir}/embedded",
    "-DCMAKE_INSTALL_PREFIX=#{install_dir}/embedded",
    "-DBUILD_CLAR=OFF",
    "-DTHREADSAFE=ON"
  ]

  command configure_command.join(' '), env: env

  command 'cmake --build . --target install', env: env
end
