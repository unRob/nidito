#!/usr/bin/env bash

set -o pipefail
if [[ ! "$MILPA_OPT_REMOTE" ]]; then
  find "$NIDITO_ROOT/services" -name '*.nomad' -o -name '*.http-service' -depth 2 |
    sort |
    sed -E 's/.*\/(.*).(nomad|http-service)/\1/'
else
  curl -s "${NOMAD_ADDR}/v1/jobs" | jq -r '.[] | .Name'
fi
