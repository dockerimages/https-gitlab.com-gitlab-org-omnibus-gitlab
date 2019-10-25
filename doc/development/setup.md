# Setting up your development environment

Development of Omnibus GitLab maybe done using an existing package available
from [Downloads page](https://about.gitlab.com/install/). To know how to setup
a build environment to build these packages and use them, please read [Setting
up a Build Environment](../build/prepare-build-environment.md).

1. Set up a container

   To provide isolation and to prevent rebuilding of the package for each and
   every change, it is preferred to use a Container for development. The
   following example uses docker on a Debian host with a Debian Jessie image.
   The steps are similar for other OSs; only the commands differ.

   1. Install docker for your OS as per [official Docker installation docs](https://docs.docker.com/install/).

   1. Choose which image to use by first choosing
   which package from the
   [Nightly Build repository](https://packages.gitlab.com/gitlab/nightly-builds)
   you would like to install. For example, if you would like to install the
   `ubuntu/bionic` nightly package, use the `ubuntu:bionic` docker image here.

      ```sh
      docker pull ubuntu:bionic
      ```

   1. Running docker image with a shell prompt

      ```sh
      docker run -it ubuntu:bionic bash
      ```

    This will cause the docker to run the bionic image and you will fall into a
    bash prompt, where the following steps are applied to.

1. Install basic necessary tools

   Basic tools used for developing Omnibus GitLab may be installed using the
   following command

   ```sh
   apt-get install git
   ```

1. Install other dependencies

   ```sh
   apt-get install openssh-server postfix tzdata curl gnupg
   ```

1. Getting GitLab CE nightly package and installing it

   Get the latest GitLab CE nightly package (of the OS you are using) from
   [Nightly Build repository](https://packages.gitlab.com/gitlab/nightly-builds)
   and install it using the instructions given on that page. Once you configure
   and start GitLab. Check if you can access it from your host browser on
   `<ip address of host>`.

   **`Note`**: Nightly packages versioning is incorrect which can cause a
   confusion. This [issue is reported in #864](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/864).
   For the time being, consider the date of pushing (which is available next
   to the package name in the repository page) to find the latest package version.

   1. Once the package is installed, you will need to set an external_url
      (in `/etc/gitlab/gitlab.rb`) so that GitLab is accessible from your host system.

      Example:

      ```
      external_url 'http://localhost'
      ```

   1. Run `gitlab-ctl reconfigure` after changing the external_url.

   1. You should now be able to access GitLab on your host machine.

      For example, if you set the `external_url` as `localhost`:

      ```
      external_url 'http://localhost'
      ```

      you will be able to access the GitLab instance from a browser on your host
      machine at the IP of the docker container where GitLab is running. (Ex: `http://172.17.0.0.1`)
      Get the IP of the docker container by running the following command on the host
      machine:

      ```bash
      docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <container_name_or_id>
      ```

1. Getting source of Omnibus GitLab

   Get the source code of Omnibus GitLab from the [repository on GitLab.com](https://gitlab.com/gitlab-org/omnibus-gitlab)

   ```sh
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   ```

   We will be doing the development inside the `~/omnibus-gitlab` directory.

1. Instructing GitLab to apply the changes we make to the cookbooks.

   During development, we need the changes we make to the cookbooks to be
   applied immediately to the running GitLab instance. So, we have to instruct
   GitLab to use those cookbooks instead of the ones shipped during
   installation. This involves backing up of the existing cookbooks directory
   and symlinking the directory where we make modifications to its location.

   ```sh
   sudo mv /opt/gitlab/embedded/cookbooks/gitlab /opt/gitlab/embedded/cookbooks/gitlab.$(date +%s)
   sudo ln -s ~/omnibus-gitlab/files/gitlab-cookbooks/gitlab /opt/gitlab/embedded/cookbooks/gitlab
   ```

   You should also do this for any folders where you have made changes. For example,
   if you have changes in the `monitoring` folder, do the following for the changes
   to be applied to the running GitLab instance:

   ```sh
   sudo mv /opt/gitlab/embedded/cookbooks/monitoring /opt/gitlab/embedded/cookbooks/monitoring.$(date +%s)
   sudo ln -s ~/omnibus-gitlab/files/gitlab-cookbooks/monitoring /opt/gitlab/embedded/cookbooks/monitoring
   ```

   You cannot currently symlink the entire cookbooks folder.

1. Docker container specific items

   Before running `gitlab-ctl reconfigure`, you need to start runsv.

   ```sh
   /opt/gitlab/embedded/bin/runsvdir-start &
   ```

   After running `gitlab-ctl reconfigure`, you may have sysctl errors. There is a workaround in the [common installation problems doc](../common_installation_problems/README.md#failed-to-modify-kernel-parameters-with-sysctl).

Now, you can make necessary changes in the
`~/omnibus-gitlab/files/gitlab-cookbooks/gitlab` folder and run `sudo gitlab-ctl reconfigure`
for those changes to take effect.

## Run GitLab QA Against Your Development Environment

You can run [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa) tests against your development instance.

This ensures that your new work is behaving as expected, and not breaking anything else. You can even add your own tests to QA to validate what you are working on.

1. Create a user account on your development instance for GitLab QA to use

   Then, from any machine that can reach your development instance:

1. Clone the [GitLab EE](https://gitlab.com/gitlab-org/gitlab) repository

   ```sh
   git clone git@gitlab.com:gitlab-org/gitlab.git
   ```

1. Change to the `qa` directory

   ```sh
   cd gitlab-ee/qa
   ```

1. Install the required gems

   ```sh
   bundle install
   ```

1. Run the tests

   ```sh
   GITLAB_USERNAME=$USERNAME GITLAB_PASSWORD=$PASSWORD bundle exec bin/qa Test::Instance $DEV_INSTANCE_URL
   ```

## Openshift GitLab Development Setup

See [openshift/README.md.](openshift/README.md)
