#!/usr/bin/env bash

set -o pipefail
if [[ ! "$MILPA_OPT_REMOTE" ]]; then
  find "$(dirname "$MILPA_COMMAND_REPO")/services" -name '*.nomad' |
    sort |
    sed -E 's/.*\/(.*).nomad/\1/'
else
  curl -s "${NOMAD_ADDR}/v1/jobs" | jq -r '.[] | .Name'
fi
