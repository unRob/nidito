#!/usr/bin/env bash

case "$MILPA_OPT_SOURCE" in
  vault)
    vault kv get "nidito/config/$MILPA_ARG_FILE/${MILPA_ARG_PATH//.//}"
  ;;
  local)
    gcy get "$CONFIG_DIR/$MILPA_ARG_FILE.yaml" "${MILPA_ARG_PATH:- .}"
  ;;
  *) @milpa.fail "Unknown source $MILPA_OPT_SOURCE"
esac
