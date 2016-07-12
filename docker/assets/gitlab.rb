# Docker options
## Prevent Postgres from trying to allocate 25% of total memory
postgresql['shared_buffers'] = '1MB'

# Manage accounts with docker
manage_accounts['enable'] = false

postgresql['username'] = 'git'
redis['username'] = 'git'
web-server['username'] = 'git'
web-server['group'] = 'git'
registry['username']  = 'git'
registry['group']  = 'git'
mattermost['username'] = 'git'
mattermost['group'] = 'git'
root_username = 'git'

# Get hostname from shell
host = `hostname`.strip
external_url "http://#{host}"

# Load custom config from environment variable: GITLAB_OMNIBUS_CONFIG
eval ENV["GITLAB_OMNIBUS_CONFIG"].to_s

# Load configuration stored in /etc/gitlab/gitlab.rb
from_file("/etc/gitlab/gitlab.rb")
