#!/usr/bin/env bash

case "$MILPA_OPT_SOURCE" in
  vault)
    vault kv get "nidito/config/$MILPA_ARG_FILE/${MILPA_ARG_PATH//.//}"
  ;;
  op)
    @milpa.load_util config
    @config.get_remote "$MILPA_ARG_FILE" "${MILPA_ARG_PATH%.}" "${MILPA_OPT_FORMAT}" "${MILPA_OPT_RAW:+raw}"
    ;;
  names)
    @milpa.load_util config
    @config.get "$MILPA_ARG_FILE" "${MILPA_ARG_PATH%.}" "${MILPA_OPT_FORMAT}" "${MILPA_OPT_RAW:+raw}"
  ;;
  *) @milpa.fail "Unknown source $MILPA_OPT_SOURCE"
esac
