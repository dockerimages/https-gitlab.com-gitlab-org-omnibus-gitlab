# Settings via Consul

In an EE environment, you can move the management of some node settings into
consul, reducing the editing of files per node.

## Configuring your cluster to use consul

TODO: Copy/reference HA docs

## Uploading data to Consul

### Author settings

Author the settings for your environment, an example is [example-consul-settings.yaml](example-consul-settings.yaml).

This is a hash with the following top level keys:

`role_settings`

`node_settings`

`role_assignments`

`role_settings` is a hash, with its key being the name of a role.  keys under this will be turned into gitlab.rb settings on nodes that have this role:

example:

```yaml
role_settings:
  app:
    gitlab_rails:
      gitlab_default_theme: 2
```

`node_settings` is a hash with its key being the name of a node.  The value under this will be turned into gitlab.rb settings on this node:

example:

```yaml
node_settings:
  app1.example.com:
    gitlab_rails:
      gitlab_default_theme: 2
```

`role_assignments` is a hash, with its key being the name of a role, and it's value being the hosts to apply the settings to

example:

```yaml
role_assignments:
  app:
    - app1.example.com
    - app2.example.com
```

### Uploading

run `gitlab-ctl upload-settings example-settings.yaml` on your lead node

Quick verify:

```console
$ /opt/gitlab/embedded/bin/consul kv get -recurse gitlab/nodes
gitlab/nodes/app1.example.com/gitlab_rails/gitlab_default_theme:2
```

## Using data from Consul

To the gitlab.rb add:

```ruby
consul['enable'] = true
# TODO: Needs better name, but a flag
gitlab['settings-from-consul'] = true
```

And then during a `gitlab-ctl reconfigure` the data you uploaded should be used in the configuration pass
