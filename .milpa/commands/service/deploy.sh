#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
spec="$NIDITO_ROOT/services/$service.nomad"

if [[ ! "$MILPA_OPT_SKIP_PLAN" ]]; then
  nomad plan -verbose "$spec"
  result="$?"
  [[ "$?" -gt 1 ]] && exit $result
fi

exec nomad run -verbose "$spec"
