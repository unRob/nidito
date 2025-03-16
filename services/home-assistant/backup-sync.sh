#!/bin/bash

source /secrets/backup-credentials.sh
set -o nounset

function fail() {
  echo "$*" >&2
  exit 2
}

echo "Starting sync to bucket $BUCKET"
rclone sync \
  --s3-acl private \
  /config/backups "remote:$BUCKET/backups" || fail "Could not sync to $RCLONE_CONFIG_REMOTE_ENDPOINT"
