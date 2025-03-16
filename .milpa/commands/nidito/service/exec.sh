#!/usr/bin/env bash

@milpa.load_util service
read -r service service_folder _ kind < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"
dc="$MILPA_OPT_DC"

if [[ "$kind" != "nomad" ]]; then
  @milpa.fail "Cannot exec on a non-nomad service of kind $kind"
fi

if [[ "$MILPA_OPT_LOCAL" ]]; then
  exec docker exec -it "$(docker ps | awk "/$1/ {print \$1}")" sh
fi

set -e pipefail
ns=$(milpa nidito service info "$service" --filter '.Job.Namespace')
alloc="$(nomad job allocs -json -namespace "$ns" "$service" | jq -r '.[0].ID')" || @milpa.fail "Could not fetch allocation for job $service"

cmd=(/bin/sh)
if [[ ${#MILPA_ARG_COMMAND[@]} -gt 0 ]]; then
  interactive="${MILPA_OPT_INTERACTIVE:-false}"
  passtty="${MILPA_OPT_TTY:-false}"
  if [[ ${#MILPA_ARG_COMMAND[@]} -eq 1 ]]; then
    cmd=("${MILPA_ARG_COMMAND[*]}")
  else
    cmd+=(-c "${MILPA_ARG_COMMAND[*]}")
  fi
else
  @milpa.log warning "Setting --tty and --interactive since we're invoking a shell"
  interactive=true
  passtty=true
fi

args=(
  -i="${interactive}"
  -t="${passtty}"
)
if [[ "${MILPA_OPT_TASK}" != "" ]]; then
  args+=( -task "$MILPA_OPT_TASK" )
fi


exec nomad alloc exec \
  -region "$dc" \
  -namespace "$ns" \
  "${args[@]}" \
  "$alloc" "${cmd[@]}"
