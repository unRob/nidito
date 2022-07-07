#!/usr/bin/env bash

case "$MILPA_OPT_SOURCE" in
  vault)
    vault kv list -format json nidito/config | jq -r 'map(sub("/"; ""))[]'
  ;;
  local)
    find "$CONFIG_DIR" -name '*.yaml' | awk -F'/' '{sub(".yaml", ""); print $NF}'
  ;;
  *) @milpa.fail "Unknown source $MILPA_OPT_SOURCE"
esac
