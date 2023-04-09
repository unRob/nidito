#!/usr/bin/env bash

dc="$1"
dst="$(date -u "+%Y-%m-%d-%H-%M-%S")-$dc.snap"

echo "dc: $dc"
echo "Taking snapshot named $dst"

set -o errexit
set -o xtrace

consul snapshot save "$dst"
trap 'rm -rf "$dst"' ERR EXIT
age --encrypt --recipient "$AGE_PUBLIC_KEY" "$dst" >"$dst.age"
mc cp "$dst.age" "backups/$BACKUP_BUCKET/$dc/$dst.age"
