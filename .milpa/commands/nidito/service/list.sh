#!/usr/bin/env bash

set -o pipefail
if [[ ! "$MILPA_OPT_REMOTE" ]]; then
  find "$NIDITO_ROOT/services" -maxdepth 2 -name '*.nomad' -o -name '*.http-service' |
    sort |
    sed -E 's/.*\/(.*).(nomad|http-service)/\1/'
else
  curl -s "${NOMAD_ADDR}/v1/jobs" | jq -r '.[] | .Name'
fi
