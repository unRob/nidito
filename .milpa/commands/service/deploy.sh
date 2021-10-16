#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
spec="$NIDITO_ROOT/services/$service.nomad"

cd "$NIDITO_ROOT/services" || @milpa.fail "services folder not found"
if [[ ! "$MILPA_OPT_SKIP_PLAN" ]]; then
  nomad plan -verbose "$spec"
  result="$?"
  [[ "$result" -gt 1 ]] && @milpa.fail "Could not run plan"
fi

exec nomad run -verbose -consul-token "$CONSUL_HTTP_TOKEN" "$spec"
