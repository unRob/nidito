#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
service_folder="$NIDITO_ROOT/services/${service}"
cd "$service_folder" || @milpa.fail "Could not cd into $service_folder"

[[ -d "$service_folder/.terraform" ]] || terraform init -backend-config "path=nidito/state/service/$(dirname "$PWD")"

if [[ "${MILPA_ARG_ARGS[*]}" ]]; then
  exec terraform "$MILPA_ARG_COMMAND" "${MILPA_ARG_ARGS[@]//\'/}"
else
  exec terraform "$MILPA_ARG_COMMAND"
fi
