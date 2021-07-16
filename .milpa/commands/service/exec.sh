#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"

if [[ "$MILPA_ARG_LOCAL" ]]; then
  exec docker exec -it "$(docker ps | awk "/$1/ {print \$1}")" sh
fi

alloc=$(curl -s "${NOMAD_ADDR}/v1/job/${service}/allocations" | jq -r '.[0].ID') || fail "Unknown job <${service}>"

if [[ "$MILPA_ARG_INTERACTIVE" == "autodetect" ]]; then
  [ -t 1 ] && interactive="true" || interactive="false"
else
  interactive="$MILPA_ARG_INTERACTIVE"
fi

if [[ "$MILPA_ARG_TTY" == "autodetect" ]]; then
  [ -t 2 ] && passtty="true" || passtty="false"
else
  passtty="$MILPA_ARG_TTY"
fi

args=(/bin/sh)
if [[ ${#@} -gt 1 ]]; then
  args+=(-c "${*}")
fi

exec nomad alloc exec \
  -i="$interactive" \
  -t="$passtty" \
  "$alloc" "${args[@]}"
