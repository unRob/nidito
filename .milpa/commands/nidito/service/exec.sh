#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
shift
if [[ "$MILPA_OPT_LOCAL" ]]; then
  exec docker exec -it "$(docker ps | awk "/$1/ {print \$1}")" sh
fi

set -e pipefail
alloc=$(curl --fail --show-error -s "${NOMAD_ADDR}/v1/job/${service}/allocations" | jq -r '.[0].ID') || @milpa.fail "Unknown job <${service}>"
echo "asdf $alloc"

interactive="${MILPA_OPT_INTERACTIVE:-false}"
passtty="${MILPA_OPT_TTY:-false}"

args=(/bin/sh)
if [[ ${#@} -gt 1 ]]; then
  args+=(-c "${MILPA_ARG_COMMAND[*]}")
fi

if [[ "${#args[@]}" -eq 1 ]] && [[ "${args[0]}" == "/bin/sh" ]]; then
  @milpa.log warning "Setting --tty and --interactive since we're invoking a shell"
  interactive=true
  passtty=true
fi

exec nomad alloc exec \
  -i="${interactive}" \
  -t="${passtty}" \
  "$alloc" "${args[@]}"
