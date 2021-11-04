#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
shift
if [[ "$MILPA_OPT_LOCAL" ]]; then
  exec docker exec -it "$(docker ps | awk "/$1/ {print \$1}")" sh
fi

alloc=$(curl -s "${NOMAD_ADDR}/v1/job/${service}/allocations" | jq -r '.[0].ID') || fail "Unknown job <${service}>"

if [[ "$MILPA_OPT_INTERACTIVE" == "autodetect" ]]; then
  [ -t 1 ] && interactive="true" || interactive="false"
else
  interactive="${MILPA_OPT_INTERACTIVE:-false}"
fi

if [[ "$MILPA_OPT_TTY" == "autodetect" ]]; then
  [ -t 2 ] && passtty="true" || passtty="false"
else
  passtty="${MILPA_OPT_TTY:-false}"
fi

args=(/bin/sh)
if [[ ${#@} -gt 1 ]]; then
  args+=(-c "${MILPA_ARG_COMMAND[*]}")
fi

exec nomad alloc exec \
  -i="$interactive" \
  -t="$passtty" \
  "$alloc" "${args[@]}"
