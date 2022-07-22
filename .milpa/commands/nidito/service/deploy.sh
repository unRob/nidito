#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
service_folder="$NIDITO_ROOT/services/$service"
spec="$service_folder/$service.nomad"
http_spec="$service_folder/$service.http-service"

cd "$service_folder" || @milpa.fail "services folder not found"

@milpa.log info "deploying $service"

export NOMAD_ADDR="${NOMAD_ADDR/.service.consul/.service.${MILPA_OPT_DC}.consul}"

if [[ -f "$spec" ]]; then
  @milpa.log info "deploying with nomad"
  # export NOMAD_ADDR="https://nomad.service.$MILPA_OPT_DC.consul:5560"
  if [[ ! "$MILPA_OPT_SKIP_PLAN" ]]; then
    nomad plan \
      -verbose \
      -region="$MILPA_OPT_DC" \
      -diff \
      "$spec"
    result="$?"
    [[ "$result" -gt 1 ]] && @milpa.fail "Could not run plan"
  fi

  exec nomad run -verbose -consul-token "$CONSUL_HTTP_TOKEN" -region="$MILPA_OPT_DC" "$spec"
fi

if [[ -f "${http_spec}" ]]; then
  exec bash "$http_spec"
fi
