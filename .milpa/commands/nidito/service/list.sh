#!/usr/bin/env bash

set -o pipefail
if [[ "$MILPA_OPT_REMOTE" ]]; then
  @milpa.log info "listing services from nomad"
  exec curl -s "${NOMAD_ADDR}/v1/jobs" | jq -r '.[] | .Name'
fi


root="$(milpa nidito service root)"
@milpa.log debug "listing services from ${root}"
find "${root}" -maxdepth 2 -name '*.spec.yaml' |
  uniq |
  while read -r spec; do
    # repo="$(basename "${spec%%/services*}")"
    service="$(basename "$(dirname "$spec")")"
    echo "$service"
  done |
  sort -u
