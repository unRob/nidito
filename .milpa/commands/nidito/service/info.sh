#!/usr/bin/env bash

@milpa.load_util service
read -r service service_folder spec kind < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"

case "$kind" in
  nomad)
    nomad job run \
      -var-file "$(nomad_vars "$service" "$spec")" \
      -output "$service.nomad" | jq -r "$MILPA_OPT_FILTER"
    ;;
  http)
    joao get --output json "$spec" . | jq -r "$MILPA_OPT_FILTER"
    ;;
  *) @milpa.fail "Unknown service kind $kind"
esac
