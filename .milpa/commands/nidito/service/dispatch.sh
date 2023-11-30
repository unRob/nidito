#!/usr/bin/env bash
@milpa.load_util service
read -r _ service_folder _ < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"

echo "$MILPA_ARG_PAYLOAD" | nomad job dispatch "$MILPA_ARG_TASK" -
