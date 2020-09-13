#!/usr/bin/env sh
exec 1>/home/icecast/mirror.log 2>&1
source /home/icecast/minio-env.sh
log () {
  echo "$(date) - $*"
}
echo "----------------------------"
kind=$(basename "${1%%.*}")
name="${1#*.}"
log "Mirror starting triggered by kind=$kind name=$name"

sleep 5

if mc --config-dir /home/icecast mirror /recordings/ cajon/ruiditos; then
  rm -rfv /recordings/*.mp3
  log "Mirror complete"
else
  log "MC crapped its pants"
fi
