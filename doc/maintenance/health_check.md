# Health check notes

You can run some basic health checks on a node before GitLab is configured by running `gitlab-ctl precheck`. These tests check only the host itself.

You can enable some more advanced health checks during reconfigure by setting `healthceck_enabled true` in `/etc/gitlab/gitlab.rb`. These will be able to check the GitLab instance itself for potential issues


## Please define an external_url
## External url "gitlab.example.com" is not resolvable by the local resolver

**Level**: warning

### Description

You have not provided a value for external_url, or the value you have set for `external_url` in `/etc/gitlab/gitlab.rb` or the EXTERNAL_URL environment variable is not resolvable in DNS by the host.

This isn't necessarily an problem in itself. If you are experiencing any of the following issues, it could be related
* Unable to access the GitLab instance at all
* Invalid SSL certificate errors

### Resolution
* Verify the value specified for `external_url` in `/etc/gitlab/gitlab.rb` is correct. If not, correct the value and run `gitlab-ctl reconfigure`
* Verify the DNS entry is correct. `dig +short HOSTNAME` should return an IP address
