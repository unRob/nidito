#!/usr/bin/env bash

@milpa.load_util service
read -r service service_folder spec < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"
http_spec="$service_folder/$service.http-service"

@milpa.log info "deploying $service"

export NOMAD_ADDR="${NOMAD_ADDR/.service.consul/.service.${MILPA_OPT_DC}.consul}"

if [[ -f "$spec" ]]; then
  @milpa.log info "deploying with nomad"
  # export NOMAD_ADDR="https://nomad.service.$MILPA_OPT_DC.consul:5560"
  @milpa.log info "Writing temporary variables for nomad job"
  varFile="${spec%%nomad}vars"
  milpa --verbose nidito service vars --output nomad "$service" >"$varFile" || @milpa.fail "Could not get vars for $service"

  if [[ ! "$MILPA_OPT_SKIP_PLAN" ]]; then
    @nidito.service.nomad.plan "$spec" "$service"
  fi

  trap 'rm $varFile' ERR EXIT
  @nidito.service.nomad.deploy "$spec" "$service" || @milpa.fail "Deploy failed"
  exit
fi

if [[ -f "${http_spec}" ]]; then
  exec bash "$http_spec"
fi
