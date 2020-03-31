# Database settings

NOTE: **Note:**
Omnibus GitLab has a bundled PostgreSQL server and PostgreSQL is the preferred
database for GitLab.

GitLab supports only PostgreSQL database management system.

Thus you have two options for database servers to use with Omnibus GitLab:

- Use the packaged PostgreSQL server included with GitLab Omnibus (no configuration required, recommended)
- Use an [external PostgreSQL server](#using-a-non-packaged-postgresql-database-management-server)

### Enabling PostgreSQL WAL (Write Ahead Log) Archiving

By default WAL archiving of the packaged PostgreSQL is not enabled. Please consider the following when
seeking to enable WAL archiving:

- The WAL level needs to be 'replica' or higher (9.6+ options are `minimal`, `replica`, or `logical`)
- Increasing the WAL level will increase the amount of storage consumed in regular operations

To enable WAL Archiving:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Replication settings
   postgresql['sql_replication_user'] = "gitlab_replicator"
   postgresql['wal_level'] = "replica"
       ...
       ...
   # Backup/Archive settings
   postgresql['archive_mode'] = "on"
   postgresql['archive_command'] = "/your/wal/archiver/here"
   postgresql['archive_timeout'] = "60"
   ```

1. [Reconfigure GitLab][] for the changes to take effect. This will result in a database restart.

### Seed the database (fresh installs only)

If you want to specify a password for the default `root` user, specify the
`initial_root_password` setting in `/etc/gitlab/gitlab.rb` before running the
`gitlab:setup` command above:

```ruby
gitlab_rails['initial_root_password'] = 'nonstandardpassword'
```

If you want to specify the initial registration token for shared GitLab Runners,
specify the `initial_shared_runners_registration_token` setting in `/etc/gitlab/gitlab.rb`
before running the `gitlab:setup` command:

```ruby
gitlab_rails['initial_shared_runners_registration_token'] = 'token'
```

### Troubleshooting

#### Set `default_transaction_isolation` into `read committed`

If you see errors similar to the following in your `production/sidekiq` log:

```
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

Chances are your database's `default_transaction_isolation` configuration is not
in line with GitLab application requirement. You can check this configuration by
connecting to your PostgreSQL database and run `SHOW default_transaction_isolation;`.
GitLab application expects `read committed` to be configured.

This `default_transaction_isolation` configuration is set in your
`postgresql.conf` file. You will need to restart/reload the database once you
changed the configuration. This configuration comes by default in the packaged
PostgreSQL server included with GitLab Omnibus.

## Packaged PostgreSQL deployed in an HA/Geo Cluster

### Upgrading a GitLab HA cluster

If [PostgreSQL is configured for high availability](https://docs.gitlab.com/ee/administration/high_availability/database.html),
`pg-upgrade` should be run all the nodes running PostgreSQL. Other nodes can be
skipped, but must be running the same GitLab version as the database nodes.
Follow the steps below to upgrade the database nodes

1. Secondary nodes must be upgraded before the primary node.
   1. On the secondary nodes, edit `/etc/gitlab/gitlab.rb` to include the following:

   ```bash
   # Replace X with value of number of db nodes + 1
   postgresql['max_replication_slots'] = X
    ```

   1. Run `gitlab-ctl reconfigure` to update the configureation.
   1. Run `sudo gitlab-ctl restart postgresql` to get PostgreSQL restarted with the new configuration.
   1. On running `pg-upgrade` on a PostgreSQL secondary node, the node will be removed
      from the cluster.
   1. Once all the secondary nodes are upgraded using `pg-upgrade`, the user
      will be left with a single-node cluster that has only the primary node.
   1. `pg-upgrade`, on secondary nodes will not update the existing data to
      match the new version, as that data will be replaced by the data from
      primary node. It will, however move the existing data to a backup
      location.
1. Once all secondary nodes are upgraded, run `pg-upgrade` on primary node.
   1. On the primary node, edit `/etc/gitlab/gitlab.rb` to include the following:

   ```bash
   # Replace X with value of number of db nodes + 1
   postgresql['max_replication_slots'] = X
    ```

   1. Run `gitlab-ctl reconfigure` to update the configureation.
   1. Run `sudo gitlab-ctl restart postgresql` to get PostgreSQL restarted with the new configuration.
   1. On a primary node, `pg-upgrade` will update the existing data to match
      the new PostgreSQL version.
1. Recreate the secondary nodes by running the following command on each of them

   ```bash
   gitlab-ctl repmgr standby setup MASTER_NODE_NAME
   ```

1. Check if the repmgr cluster is back to the original state

   ```bash
   gitlab-ctl repmgr cluster show
   ```

NOTE: **Note:**
As of GitLab 12.8, you can opt into upgrading PostgreSQL 11 with `pg-upgrade -V 11`

### Troubleshooting upgrades in an HA cluster

If at some point, the bundled PostgreSQL had been running on a node before upgrading to an HA setup, the old data directory may remain. This will cause `gitlab-ctl reconfigure` to downgrade the version of the PostgreSQL utilities it uses on that node. Move (or remove) the directory to prevent this:

- `mv /var/opt/gitlab/postgresql/data/ /var/opt/gitlab/postgresql/data.$(date +%s)`

If you encounter the following error when recreating the secondary nodes with `gitlab-ctl repmgr standby setup MASTER_NODE_NAME`, ensure that you have `postgresql['max_replication_slots'] = X`, replacing `X` with value of number of db nodes + 1, is included in `/etc/gitlab/gitlab.rb`:

```bash
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.

```

### Upgrading a Geo instance

CAUTION: **Caution:**
If you are running a Geo installation using PostgreSQL 9.6.x, please upgrade to GitLab 12.4 or newer. Older versions were affected [by an issue](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4692) that could cause automatic upgrades of the PostgreSQL database to fail on the secondary. This issue is now fixed.

As of GitLab 12.1, `gitlab-ctl pg-upgrade` can automatically upgrade the database on your Geo servers.

NOTE: **Note:**
Due to how PostgreSQL replication works, this cannot be done without the need to resynchronize your secondary database server. Therefore, this upgrade cannot be done without downtime.

If you want to skip the automatic upgrade, before you install 12.1 or newer, run the following:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

To upgrade a Geo cluster, you will need a name for the replication slot, and the password to connect to the primary server.

1. Find the existing name of the replication slot name on the primary node, run:

   ```shell
   sudo gitlab-psql -qt -c 'select slot_name from pg_replication_slots'
   ```

1. Upgrade the `gitlab-ee` package on the Geo primary server.
   Or to manually upgrade PostgreSQL, run:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

1. Upgrade the `gitlab-ee` package on the Geo secondary servers.
   Or manually upgrade PostgreSQL, run:

   ```shell
   sudo gitlab-ctl pg-upgrade
   ```

   NOTE: **Note:**
   In a [Geo HA](https://docs.gitlab.com/ee/administration/geo/replication/high_availability.html) setup with databases
   managed by GitLab Omnibus, you should run the command above on both the Geo **secondary database**, and also on the
   **tracking database**.

1. Re-initialize the database on the Geo secondary server using the command

   ```shell
   sudo gitlab-ctl replicate-geo-database --slot-name=SECONDARY_SLOT_NAME --host=PRIMARY_HOST_NAME
   ```

   You will be prompted for the password of the primary server.

   NOTE: **Note:**
   In a [Geo HA](https://docs.gitlab.com/ee/administration/geo/replication/high_availability.html) setup with databases
   managed by GitLab Omnibus, the command above should be run on your Geo **secondary database**.

1. Refresh the foreign tables on the Geo secondary server using the command

   ```shell
   sudo gitlab-rake geo:db:refresh_foreign_tables
   ```

   NOTE: **Note:**
   In a [Geo HA](https://docs.gitlab.com/ee/administration/geo/replication/high_availability.html) setup with databases
   managed by GitLab Omnibus, the command above should be run on your Geo **tracking database**.

1. Restart `unicorn`, `sidekiq`, and `geo-logcursor`.

   ```shell
   sudo gitlab-ctl hup unicorn
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. Navigate to `https://your_primary_server/admin/geo/nodes` and ensure that all nodes are healthy

[rake-backup]: https://docs.gitlab.com/ee/raketasks/backup_restore.html#create-a-backup-of-the-gitlab-system "Backup raketask documentation"
[Reconfigure GitLab]: https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure "Reconfigure GitLab"
[rake-restore]: https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-a-previously-created-backup "Restore raketask documentation"
[database requirements document]: https://docs.gitlab.com/ee/install/requirements.html#database
