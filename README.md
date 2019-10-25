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

CURRENT_USER=$(id -un)
CURRENT_GROUP=$(id -gn)

CURRENT_USER_ID=$(id -u)
CURRENT_GROUP_ID=$(id -g)

docker build --no-cache \
	-t "rubensa/ubuntu-systemd-user" \
	--label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
	--build-arg USER=$CURRENT_USER \
	--build-arg GROUP=$CURRENT_GROUP \
	--build-arg USER_ID=$CURRENT_USER_ID \
	--build-arg GROUP_ID=$CURRENT_GROUP_ID \
	.
```

But this is generally not needed as the container can change user ID and group ID on run if USER_ID or GROUP_ID environment variables are provided on container run (see bellow).

## Running

You can run the container like this (change --rm with -d if you don't want the container to be removed on stop):

```
#!/usr/bin/env bash

CURRENT_USER_UID=$(id -u)
CURRENT_USER_GID=$(id -g)

docker run --rm -it \
  --name "ubuntu-systemd-user" \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v /etc/timezone:/etc/timezone:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -e USER_ID=$CURRENT_USER_UID \
  -e GROUP_ID=$CURRENT_USER_GID \
  rubensa/ubuntu-systemd-user
```

NOTE: Mounting /etc/timezone and /etc/localtime allows you to use your host timezone on container.

Specifying USER_ID, and GROUP_ID environment variables on run, makes the system change internal user UID and group GID to that provided.  This also changes files under /home directory that are owned by user and group to those provided.

This allows to set default owner of the files to you (very usefull for mounted volumes).

## Connect

You can connect to the running container like this:

```
#!/usr/bin/env bash

IMAGE_USER=user

docker exec -it \
  -u $IMAGE_USER \
  -w /home/$IMAGE_USER \
  ubuntu-systemd-user \
  bash -l
```

This creates a bash shell run by the specified user (that must exist in the container - by default "user" if not specified other on container build)

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

docker start ubuntu-systemd-user
```
