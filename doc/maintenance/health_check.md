# Health check notes

After `gitlab-ctl reconfigure` is run, a basic health check is run against the GitLab instance to check for any potential issues.

## Host "gitlab.example.com" is not a resolvable external_url

**Level**: warning

### Description

The value you have set for `external_url` in `/etc/gitlab/gitlab.rb` is not resolvable in DNS by the host.

This isn't necessarily an problem in itself. If you are experiencing any of the following issues, it could be related
* Unable to access the GitLab instance at all
* Invalid SSL certificate errors

### Resolution
* Verify the value specified for `external_url` in `/etc/gitlab/gitlab.rb` is correct. If not, correct the value and run `gitlab-ctl reconfigure`
* Verify the DNS entry is correct. `dig +short HOSTNAME` should return an IP address
