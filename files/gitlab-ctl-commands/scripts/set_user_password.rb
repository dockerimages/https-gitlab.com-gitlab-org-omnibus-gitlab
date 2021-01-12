script_file = ARGV[0]

credential_contents = ::File.readlines(script_file)
username = credential_contents[0].chomp
password = credential_contents[1..].join

user = User.find_by_username(username)

unless user
  warn "Unable to find user with username '#{username}'."
  Kernel.exit 1
end

user.update!(password: password, password_confirmation: password, password_automatically_set: false)
