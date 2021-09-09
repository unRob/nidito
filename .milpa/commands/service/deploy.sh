#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
spec="$(dirname "$MILPA_COMMAND_REPO")/services/$service.nomad"

if [[ ! "$MILPA_OPT_SKIP_PLAN" ]]; then
  nomad plan -verbose "$spec"
  result="$?"
  [[ "$result" -gt 1 ]] && @milpa.fail "Could not run plan"
fi

exec nomad run -verbose "$spec"
