#!/usr/bin/env bash

@milpa.load_util service
read -r service service_folder spec < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"

nomad job run \
  -var-file "$(nomad_vars "$service" "$spec")" \
  -output "$service.nomad" | jq -r "$MILPA_OPT_FILTER"
