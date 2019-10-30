# Docker image based on rubensa/ubuntu-systemd with non root user support

This is a Docker image with Ubuntu running systemd init system inside a container that allows you to connect and run with a non-root user created inside de image.

## Building

You can build the image like this:

```
#!/usr/bin/env bash

docker build --no-cache \
  -t "rubensa/ubuntu-systemd-user" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
```

You can add docker build image args to change default non-root user (user:1000) and group (group:1000) like this:

```
#!/usr/bin/env bash

# Get current user UID
USER_ID=$(id -u)
# Get current user main GUID
GROUP_ID=$(id -g)
# Get current user name
USER_NAME=$(id -un)
# Get current user main group name
GROUP_NAME=$(id -gn)

prepare_docker_user_and_group() {
  # On build, if you specify USER_NAME, USER_ID, GROUP_NAME or GROUP_ID those are used to define the
  # internal user and group created instead of default ones (user:1000 and group:1000)
  BUILD_ARGS+=" --build-arg USER_ID=$USER_ID"
  BUILD_ARGS+=" --build-arg GROUP_ID=$GROUP_ID"
  BUILD_ARGS+=" --build-arg USER=$USER_NAME"
  BUILD_ARGS+=" --build-arg GROUP=$GROUP_NAME"
}

prepare_docker_user_and_group

docker build --no-cache \
  -t "rubensa/ubuntu-systemd-user" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  ${BUILD_ARGS} \
  .
```

But this is generally not needed as the container can change user ID and group ID on run if USER_ID or GROUP_ID environment variables are provided on container run (see bellow).

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
#!/usr/bin/env bash

# Get current user UID
USER_ID=$(id -u)
# Get current user main GUID
GROUP_ID=$(id -g)

prepare_docker_systemd() {
  # https://developers.redhat.com/blog/2016/09/13/running-systemd-in-a-non-privileged-container/
  # Systemd expects /run is mounted as a tmpfs
  MOUNTS+=" --mount type=tmpfs,destination=/run"
  # Systemd expects /run/lock to be a separate mount point (https://github.com/containers/libpod/issues/3295)
  MOUNTS+=" --mount type=tmpfs,destination=/run/lock"
  # Systemd expects /sys/fs/cgroup filesystem is mounted.  It can work with it being mounted read/only.
  MOUNTS+=" --mount type=bind,source=/sys/fs/cgroup,target=/sys/fs/cgroup,readonly"
  # Systemd expects /sys/fs/cgroup/systemd be mounted read/write.
  # Not needed as the subdir/mount points (/sys/fs/cgroup is already mounted) will be mounted in as read/write
  #MOUNTS+=" --mount type=bind,source=/sys/fs/cgroup/systemd,target=/sys/fs/cgroup/systemd"
}

prepare_docker_timezone() {
  # https://www.waysquare.com/how-to-change-docker-timezone/
  MOUNTS+=" --mount type=bind,source=/etc/timezone,target=/etc/timezone,readonly"
  MOUNTS+=" --mount type=bind,source=/etc/localtime,target=/etc/localtime,readonly"
}

prepare_docker_user_and_group() {
  # On run, if you specify USER_ID or GROUP_ID environment variables the system change internal user UID and group GID to that provided.
  # This also changes file ownership for those under /home owned by build-time UID and GUID.
  ENV_VARS+=" --env=USER_ID=$USER_ID"
  ENV_VARS+=" --env=GROUP_ID=$GROUP_ID"
}

prepare_docker_systemd
prepare_docker_timezone
prepare_docker_user_and_group

docker run --rm -it \
  --name "ubuntu-systemd-user" \
  ${ENV_VARS} \
  ${MOUNTS} \
  rubensa/ubuntu-systemd-user
```

*NOTE*: Mounting /etc/timezone and /etc/localtime allows you to use your host timezone on container.

Specifying USER_ID, and GROUP_ID environment variables on run, makes the system change internal user UID and group GID to that provided.  This also changes files under /home directory that are owned by user and group to those provided.

This allows to set default owner of the files to you (very usefull for mounted volumes).

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

IMAGE_BUILD_USER_NAME=user

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-systemd-user \
  bash -l
```

This creates a bash shell run by the specified user (that must exist in the container - by default "user" if not specified other on container build)

*NOTE*:  Keep in mind that if you do not specify user, the command is run as root in the container.

If you added docker build image args to change default non-root user you sould connect to the running container like this:

```
#!/usr/bin/env bash

# Get current user name
IMAGE_BUILD_USER_NAME=$(id -un)

docker exec -it \
  -u $IMAGE_BUILD_USER_NAME \
  -w /home/$IMAGE_BUILD_USER_NAME \
  ubuntu-systemd-user \
  bash -l
```


## Stop

You can stop the running container like this:

```
#!/usr/bin/env bash

docker stop \
  ubuntu-systemd-user
```

## Start

If you run the container without --rm you can start it again like this:

```
#!/usr/bin/env bash

docker start \
  ubuntu-systemd-user
```
