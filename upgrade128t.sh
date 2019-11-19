#!/usr/bin/env bash

ENV_FILE="/etc/128technology/128tupgrade_on_next_boot"

# if script is not passed "true" as first arg, exit
if [ "$1" != "true" ]
then
  echo "Upgrade flag not set."
  exit 0
fi

# if 128T is running for some reason, exit
systemctl is-active --quiet 128T
if [ $? -eq 0 ]
then
  echo "128T is running...exiting."
  exit 0
fi

# check if update exists in local repo, and apply if one is found
echo "Checking to see if local update is available..."
dnf check-update --disablerepo=* --enablerepo=128tech-local-saved 128T > /dev/null 2>&1
if [ $? -eq 100 ]
then
  echo "Update is available. Proceeding to upgrade..."
  /usr/bin/install128t -p "{\"enable-128T\": true, \"start-128T\": false, \"upgrade\": {\"128T-version\":\"$2\"}, \"retry-max-attempts\": 1, \"reboot-if-required\": true}" > /dev/null 2>&1
else
  echo "No local update available."
  sed -i 's/UPGRADE_ON_BOOT=true/UPGRADE_ON_BOOT=false/g' $ENV_FILE
fi

exit 0
