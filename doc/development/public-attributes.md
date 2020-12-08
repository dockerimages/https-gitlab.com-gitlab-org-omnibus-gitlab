---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Working with `public_attributes.json`

Chef stores a copy of a nodes attributes at the end of a reconfigure in `/opt/gitlab/embedded/nodes/$NODE_NAME.json`. Due to the sensitive nature of some of the attributes, it is only readable by the root user. To work around this, we've created a file (defaults to `/var/opt/gitlab/public_attributes.json`) which contains a set of attributes we've allowlisted for use of non-root services. This file is recreated on every run of `gitlab-ctl reconfigure`.

## Adding an entry to `public_attributes.json`

The `public_attributes.json` file is populated by filtering all node attributes with our allowlist. For example:

```ruby
default['attribute_allowlist'] = [
  'gitlab/test',
]
```

The way this works is filtering all subtrees from the default node attributes using the keys in the `attribute_allowlist` list, split by `/`. This uses [Chef's AttributeAllowlist](https://www.rubydoc.info/gems/chef/Chef/AttributeAllowlist).

The above would allow any entries under `{ 'gitlab': 'test': * }`, be it a string, or a full subtree. If the key actually contains `/`, you can use an array representing the subtree structure instead, for example, if the structure was:

```ruby
{
  'gitlab': {
    'test': 'non-sensitive1',
    'test1/test2': 'non-sensitive2',
    'test3': 'SENSITIVE-KEY'
  }
}
```

You could use:

```ruby
default['attribute_allowlist'] = [
  'gitlab/test',
  ['gitlab', 'test1/test2']
]
```

The allowlist file is currently stored as [`attribute_allowlist.rb` in the `gitlab` cookbook](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/package/libraries/handlers/gitlab.rb#L36).

## Reading an entry from `public_attributes.json` from a `gitlab-ctl` command

In order to access the public nodes, you should use the provided [`GitlabCtl::Util.get_public_node_attributes` method](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/attribute_allowlist.rb)

```ruby
attributes = GitlabCtl::Util.get_public_node_attributes

puts attributes['gitlab']['test']
```
