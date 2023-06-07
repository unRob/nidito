#!/usr/bin/env bash

function @garage.curl() {
  local url; url="$1"; shift;
  curl "${MILPA_VERBOSE:---silent}${MILPA_VERBOSE:+--verbose}" -H "Authorization: Bearer $(joao get ~/src/nidito/services/garage/garage.joao.yaml token.admin)" \
    "https://api.garage.nidi.to/v0/$url" \
    "$@"
}
