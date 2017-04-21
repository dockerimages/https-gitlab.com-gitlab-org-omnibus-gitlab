# GitLab OpenShift Templates

These templates add various GitLab applications to your OpenShift cluster.

The templates can be added to your cluster by running:

`oc create -f <template-file> -n <your-openshift-project>`

And then will show up in your project's template chooser. (When using 'Add to
Project' in the OpenShift UI console)

## gitlab-ce template

- **filename**:  `gitlab-ce-template.json`
- **production ready?**: No

This template creates a full GitLab CE instance within your OpenShift project.

Includes pods for:
- GitLab CE
- Redis
- PostgreSQL

This template is provided as an example and development setup. It is not considered
production ready because of the performance limitations of it's postgres deploy.
The lack of support for external git over ssh. And lacking established backup
procedures.

### service user
The `gitlab-ce-template.json` template creates a service user for the gitlab
application. The service user's name is `<application-name>-user` where
`application-name` is one of the parameters you can specify for the gitlab-ce
template when adding it, and defaults to `gitlab-ce`.

This user requires the ability to run as pid `0` (`root`) in the container. In
order to run the GitLab application. In OpenShift this means an administrator
needs to add the user to the `anyuid` security context.

They can do this by running:

```bash
oc adm policy add-scc-to-user anyuid system:serviceaccount:<project-name>:<application-name>-user
```

The GitLab application deployment will fail to successfully start until this has
been done.

### persistent volumes

The `gitlab-ce-template.json` template uses 4 persistent volumes, and will not
deploy into a cluster without persistent volumes enabled.

## runner template

- **filename**: `runner-template.json`
- **production ready?**: Yes

This template creates a GitLab Multi-Runner manager in your OpenShift project.

It defaults to executing GitLab CI jobs using the multi-runner's kubernetes
executor.

By deploying the multi-runner in OpenShift, it is able to automatically detect
and use the OpenShift kubernetes config to create new pods for CI job execution.

While this template is production ready, it is still provided as an example. Due
to it using privileged mode, it cannot be deployed in most PaaS offerings in it's
current form.

### service user
The `runner-template.json` template creates a service user for the runner
application. The service user's name is `<application-name>-user` where
`application-name` is one of the parameters you can specify for the gitlab-runner
template when adding it, and defaults to `gitlab-runner`.

This user requires the ability to run as privileged container in order to support
dind builds. In order to run the Runner application. In OpenShift this means an
administrator needs to add the user to the `privileged` security context.

They can do this by running:

```bash
oc adm policy add-scc-to-user privileged system:serviceaccount:<project-name>:<application-name>-user
```

The Runner application deployment will fail to successfully start until this has
been done.
