# GitLab CI

You can run a [GitLab CI](https://about.gitlab.com/gitlab-ci/) Coordinator
service on your GitLab server.

## Documentation version

Please make sure you are viewing the documentation for the version of
omnibus-gitlab you are using. In most cases this should be the highest numbered
stable branch (example shown below).

![documentation version](doc/images/omnibus-documentation-version.png)

## Getting started

GitLab CI expects to run on its own virtual host. In your DNS you would then
have two entries pointing to the same machine, e.g. `gitlab.example.com` and
`ci.example.com`.

GitLab CI is disabled by default, to enable it just tell omnibus-gitlab what 
the external URL for the CI server is:

```
# in /etc/gitlab/gitlab.rb
ci_external_url 'http://ci.example.com'
```

After you run `sudo gitlab-ctl reconfigure`, your GitLab CI Coordinator should
now be reachable at `http://ci.example.com`.

Follow the on screen instructions on how to generate the app id and secret.
Once generated, add them to `/etc/gitlab/gitlab.rb`

```
gitlab_ci['gitlab_server'] = { 'url' => 'http://gitlab.example.com', 'app_id' => "1234", 'app_secret' => 'qwertyuio'}
```

and run `sudo gitlab-ctl reconfigure` again.

## Running GitLab CI on its own server

If you want to run GitLab and GitLab CI Coordinator on two separate servers you
can use the following settings on the GitLab CI server to effectively disable
the GitLab service bundled into the Omnibus package. The GitLab services will
still be set up on your CI server, but they will not accept user requests or
consume system resources.

```
external_url 'http://localhost'
ci_external_url 'http://ci.example.com'

# Tell GitLab CI to integrate with gitlab.example.com
gitlab_ci['gitlab_server'] = { 'url' => 'http://gitlab.example.com', 'app_id' => "1234", 'app_secret' => 'qwertyuio'}

# Shut down GitLab services on the CI server
unicorn['enable'] = false
sidekiq['enable'] = false
```

## Scheduling a backup

To schedule a cron job that backs up your GitLab CI, use the root user:

```
sudo su -
crontab -e
```

There, add the following line to schedule the backup for everyday at 2 AM:

```
0 2 * * * /opt/gitlab/bin/gitlab-ci-rake backup:create CRON=1
```

You may also want to set a limited lifetime for backups to prevent regular
backups using all your disk space.  To do this add the following lines to
`/etc/gitlab/gitlab.rb` and reconfigure:

```
# limit backup lifetime to 7 days - 604800 seconds
gitlab_ci['backup_keep_time'] = 604800
```

NOTE: This cron job does not [backup your omnibus-gitlab configuration](#backup-and-restore-omnibus-gitlab-configuration).

## Restoring an application backup

We will assume that you have installed GitLab CI from an omnibus package and run
`sudo gitlab-ctl reconfigure` at least once.

First make sure your backup tar file is in `/var/opt/gitlab/backups`.

```shell
sudo cp 1393513186_gitlab_ci_backup.tar.gz /var/opt/gitlab/backups/
```

Next, restore the backup by running the restore command. You need to specify the
timestamp of the backup you are restoring.

```shell
# Stop processes that are connected to the database
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq

# This command will overwrite the contents of your GitLab CI database!
sudo gitlab-ci-rake backup:restore BACKUP=1393513186

# Start GitLab
sudo gitlab-ctl start


If there is a GitLab version mismatch between your backup tar file and the installed
version of GitLab, the restore command will abort with an error. Install a package for
the [required version](https://www.gitlab.com/downloads/archives/) and try again.