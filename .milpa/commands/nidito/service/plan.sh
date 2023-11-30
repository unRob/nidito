#!/usr/bin/env bash
@milpa.load_util service
read -r service service_folder spec < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"

export NOMAD_ADDR="${NOMAD_ADDR/.service.consul/.service.${MILPA_OPT_DC}.consul}"

if [[ ! -f "$spec" ]]; then
  @milpa.fail "Nothing to plan for $service: not a nomad job"
fi

@nidito.service.nomad.plan "$spec" "$service"
