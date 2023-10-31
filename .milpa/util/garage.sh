#!/usr/bin/env bash

function @garage.curl() {
  local url logging; url="$1"; shift;
  logging="--silent"
  [[ "$MILPA_VERBOSE" ]] && logging="--verbose"
  curl "$logging" --fail --show-error \
    -H "Authorization: Bearer $(joao get ~/src/nidito/services/garage/garage.joao.yaml token.admin)" \
    "https://api.garage.nidi.to/v1/$url" \
    "$@"
}

function @garage.role_table() {
  jq -r \
    --arg table "$1" \
    '["id", "zone", "capacity", "tags"],
    (.[$table] | map([.id, .zone, (.capacity/1024/1024/1024), (.tags | join(","))]) | sort)[] |
    @tsv' "$2" | column -t
}
