#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
service_folder="$NIDITO_ROOT/services/$service"
spec="$service_folder/$service.nomad"
http_spec="$service_folder/$service.http-service"

cd "$service_folder" || @milpa.fail "services folder not found"

if [[ -f "$spec" ]]; then
  if [[ ! "$MILPA_OPT_SKIP_PLAN" ]]; then
    nomad plan -verbose "$spec"
    result="$?"
    [[ "$result" -gt 1 ]] && @milpa.fail "Could not run plan"
  fi

  exec nomad run -verbose -consul-token "$CONSUL_HTTP_TOKEN" -region="$NOMAD_OPT_DC" "$spec"
fi

if [[ -f "${http_spec}" ]]; then
  exec bash "$http_spec"
fi
