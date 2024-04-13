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

if mc --config-dir /home/icecast mirror /recordings/ "garage/$TARGET_BUCKET/dropbox"; then
  log "Mirror complete"
  rm -rfv /recordings/*.mp3
  log "dispatching processing job"

  if curl --fail --show-error --silent \
    --unix-socket "${NOMAD_SECRETS_DIR}/api.sock" \
    -H "Authorization: Bearer ${NOMAD_TOKEN}" \
    -XPOST \
    -v localhost/v1/job/radio-processing/dispatch \
    --data "{}"; then
    log "dispatched job"
    exit 0
  fi
  log "could not dispatch job"
else
  log "MC crapped its pants"
fi
