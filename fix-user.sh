#!/bin/bash
# Import our environment variables from systemd
for e in $(tr "\000" "\n" < /proc/1/environ); do
  eval "export $e"
done

export OLD_USER_ID=$(getent passwd $USER | cut -d: -f3)
export OLD_GROUP_ID=$(getent group $GROUP | cut -d: -f3)

if [ "$USER_ID" != "$OLD_USER_ID" ]; then
  usermod -u $USER_ID $USER
  find /home/ -user $OLD_USER_ID -exec chown -h $USER_ID {} \;
  echo "Changed USER_ID from $OLD_USER_ID to $USER_ID" | systemd-cat -t fix-user -p info
else
  echo "USER_ID $USER_ID not changed" | systemd-cat -t fix-user -p info
fi

if [ "$GROUP_ID" != "$OLD_GROUP_ID" ]; then
  groupmod -g $GROUP_ID $GROUP
  find /home/ -group $OLD_GROUP_ID -exec chgrp -h $GROUP_ID {} \;

  usermod -g $GROUP_ID $USER
  echo "Changed GROUP_ID from $OLD_GROUP_ID to $GROUP_ID" | systemd-cat -t fix-user -p info
else
  echo "GROUP_ID $GROUP_ID not changed" | systemd-cat -t fix-user -p info
fi